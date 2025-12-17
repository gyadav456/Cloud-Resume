import json
import boto3
import os
from decimal import Decimal
from datetime import datetime, timedelta

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('TABLE_NAME', 'VisitorCounter')
table = dynamodb.Table(TABLE_NAME)

# Initialize S3 client
s3 = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'gauravyadav.site')

# Initialize CloudWatch client
cloudwatch = boto3.client('cloudwatch')


# Helper class to convert DynamoDB Decimal to float/int for JSON serialization
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    
    # default headers for CORS
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS, POST, GET'
    }

    try:
        # Handle OPTIONS request for CORS preflight
        if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
            
        # Route Handling
        route_key = event.get('routeKey')
        path = event.get('rawPath')
        
        # --- GET /gallery: List S3 Photos ---
        if route_key == 'GET /gallery' or path == '/gallery':
            try:
                response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix='photos/')
                image_urls = []
                if 'Contents' in response:
                    for obj in response['Contents']:
                        key = obj['Key']
                        # Filter for images and exclude directories
                        if key.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')) and not key.endswith('/'):
                            # Construct public URL (assuming bucket is public/cloudfront)
                            # Using the domain directly as we know it
                            url = f"https://{BUCKET_NAME}/{key}"
                            image_urls.append(url)
                
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({'images': image_urls})
                }
            except Exception as e:
                print(f"S3 Error: {str(e)}")
                return {
                    'statusCode': 500,
                    'headers': headers,
                    'body': json.dumps({'error': 'Failed to fetch gallery images'})
                }
                }

        # --- GET /metrics: Fetch CloudWatch Stats ---
        if route_key == 'GET /metrics' or path == '/metrics':
            try:
                end_time = datetime.utcnow()
                start_time = end_time - timedelta(days=1)
                
                # Metric 1: Invocations (Traffic)
                invocations = cloudwatch.get_metric_statistics(
                    Namespace='AWS/Lambda',
                    MetricName='Invocations',
                    Dimensions=[{'Name': 'FunctionName', 'Value': context.function_name}],
                    StartTime=start_time,
                    EndTime=end_time,
                    Period=3600, # 1 Hour buckets
                    Statistics=['Sum']
                )
                
                # Metric 2: Duration (Latency)
                latency = cloudwatch.get_metric_statistics(
                    Namespace='AWS/Lambda',
                    MetricName='Duration',
                    Dimensions=[{'Name': 'FunctionName', 'Value': context.function_name}],
                    StartTime=start_time,
                    EndTime=end_time,
                    Period=3600,
                    Statistics=['Average']
                )
                
                # Sort data points by timestamp
                def sort_points(points):
                    return sorted(points, key=lambda x: x['Timestamp'])
                    
                data = {
                    'invocations': sort_points(invocations['Datapoints']),
                    'latency': sort_points(latency['Datapoints'])
                }

                # Date serialization helper
                def json_serial(obj):
                    if isinstance(obj, datetime):
                        return obj.isoformat()
                    raise TypeError ("Type not serializable")

                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(data, default=json_serial)
                }
            except Exception as e:
                print(f"Metrics Error: {str(e)}")
                return {
                    'statusCode': 500,
                    'headers': headers,
                    'body': json.dumps({'error': str(e)})
                }

        # --- POST /visitor (or Default): Update Stats ---
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except:
                pass

        action = body.get('action', 'view') # 'view' or 'download'

        # Counters are stored in a single item with partition key 'id' = 'stats'
        update_expression = "ADD views :inc"
        expression_attribute_values = {':inc': 1}
        expression_attribute_names = {'#v': 'views'} # Default
        
        if action == 'download':
            update_expression = "ADD #d :inc"
            expression_attribute_names = {'#d': 'downloads'}
        else:
            # Default to view
            expression_attribute_names = {'#v': 'views'}
            
        # Update specific counter
        response = table.update_item(
            Key={'id': 'stats'},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="UPDATED_NEW"
        )
        
        final_stats = table.get_item(Key={'id': 'stats'})
        item = final_stats.get('Item', {})
        
        # Ensure defaults if first run
        if 'views' not in item: item['views'] = 0
        if 'downloads' not in item: item['downloads'] = 0

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(item, cls=DecimalEncoder)
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
