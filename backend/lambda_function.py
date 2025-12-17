import json
import boto3
import os
from decimal import Decimal

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('TABLE_NAME', 'VisitorCounter')
table = dynamodb.Table(TABLE_NAME)

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

        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except:
                pass

        action = body.get('action', 'view') # 'view' or 'download' NOTE: Defaulting to view if simpler GET request

        # Counters are stored in a single item with partition key 'id' = 'stats'
        # We use atomic updates (ADD) to ensure thread safety
        
        update_expression = "ADD views :inc"
        expression_attribute_values = {':inc': 1}
        
        if action == 'download':
            update_expression = "ADD #d :inc"
            expression_attribute_names = {'#d': 'downloads'}
        else:
            update_expression = "ADD #v :inc"
            expression_attribute_names = {'#v': 'views'}
            
        # Update specific counter
        response = table.update_item(
            Key={'id': 'stats'},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="UPDATED_NEW"
        )
        
        # Determine what to return. 
        # Ideally we want to return BOTH current counts.
        # So we do a GetItem to return the full stats state after update, 
        # or rely on ReturnValues usually meant for just the updated attr.
        # Let's just fetch the full item to be clean and return total stats.
        
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
