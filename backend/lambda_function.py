import json
import boto3
import os
from decimal import Decimal
from datetime import datetime, timedelta
from botocore.config import Config

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
                gallery_bucket = os.environ.get('GALLERY_BUCKET_NAME', BUCKET_NAME) # Use dedicated bucket if set
                
                # IMPORTANT: Gallery bucket is in ap-south-1. Lambda is in us-east-1.
                # We must use a regional client to sign the URL correctly.
                # Explicitly enforce SigV4 which is required for ap-south-1
                s3_gallery = boto3.client('s3', region_name='ap-south-1', config=Config(signature_version='s3v4'))
                
                response = s3_gallery.list_objects_v2(Bucket=gallery_bucket) # List root of gallery bucket
                image_urls = []
                if 'Contents' in response:
                    for obj in response['Contents']:
                        key = obj['Key']
                        # Filter for images and exclude directories
                        if key.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')) and not key.endswith('/'):
                            # Generate Presigned URL (works even if bucket is private)
                            try:
                                url = s3_gallery.generate_presigned_url('get_object',
                                                                Params={'Bucket': gallery_bucket,
                                                                        'Key': key},
                                                                ExpiresIn=3600) # 1 Hour expiry
                                image_urls.append(url)
                            except Exception as e:
                                print(f"Error generating presigned url for {key}: {str(e)}")
                
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

                sorted_invocations = sort_points(invocations['Datapoints'])
                sorted_latency = sort_points(latency['Datapoints'])

                # Calculate Aggregates
                total_invocations = sum(item['Sum'] for item in sorted_invocations)
                
                if sorted_latency:
                    avg_duration = sum(item['Average'] for item in sorted_latency) / len(sorted_latency)
                else:
                    avg_duration = 0.0
                    
                # Format for Chart (Time Series)
                # We will return the latency points for the chart
                chart_data = []
                for point in sorted_latency:
                    chart_data.append({
                        'timestamp': point['Timestamp'].isoformat(),
                        'value': point['Average']
                    })

                data = {
                    'invocations': sorted_invocations, # Raw data if needed
                    'latency': sorted_latency,         # Raw data if needed
                    'total_invocations': total_invocations,
                    'avg_duration': avg_duration,
                    'chart_data': chart_data
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

        if action == 'download':
            update_expression = "SET #d = if_not_exists(#d, :start) + :inc"
            expression_attribute_names = {'#d': 'downloads'}
        else:
            # Default to view
            update_expression = "SET #v = if_not_exists(#v, :start) + :inc"
            expression_attribute_names = {'#v': 'views'}

        response = table.update_item(
            Key={'id': 'visitor_stats'},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues={
                ':inc': 1,
                ':start': 0
            },
            ReturnValues="UPDATED_NEW"
        )
        
        # Now fetch the COMPLETE stats to return to frontend
        # (Frontend expects { views: X, downloads: Y })
        final_item = table.get_item(Key={'id': 'visitor_stats'})
        item = final_item.get('Item', {})
        
        views_count = int(item.get('views', item.get('count', 0))) # Fallback to old 'count' if views empty
        downloads_count = int(item.get('downloads', 0))



        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'views': views_count,
                'downloads': downloads_count
            }, cls=DecimalEncoder)
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
