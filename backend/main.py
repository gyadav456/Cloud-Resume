from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel
import boto3
import os
import json
from decimal import Decimal
from datetime import datetime, timedelta
from botocore.config import Config

app = FastAPI()

# Input Models
class VisitorAction(BaseModel):
    action: str = "view"

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus Instrumentation
Instrumentator().instrument(app).expose(app)

# Initialize AWS Clients
# In K8s, these will pick up IAM Roles for Service Accounts (IRSA) or Env Vars
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
TABLE_NAME = os.environ.get('TABLE_NAME', 'VisitorCounter')
table = dynamodb.Table(TABLE_NAME)

s3 = boto3.client('s3', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'gauravyadav.site')
GALLERY_BUCKET_NAME = os.environ.get('GALLERY_BUCKET_NAME', 'g2u7a8.photos')

cloudwatch = boto3.client('cloudwatch', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# Helper
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/gallery")
def get_gallery():
    try:
        # Gallery bucket is in ap-south-1
        s3_gallery = boto3.client('s3', region_name='ap-south-1', config=Config(signature_version='s3v4'))
        
        response = s3_gallery.list_objects_v2(Bucket=GALLERY_BUCKET_NAME)
        image_urls = []
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')) and not key.endswith('/'):
                    url = f"https://s3.ap-south-1.amazonaws.com/{GALLERY_BUCKET_NAME}/{key}"
                    image_urls.append(url)
        
        return {"images": image_urls}
    except Exception as e:
        print(f"S3 Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics")
def get_metrics():
    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=1)
        
        # We need to know the *Function Name* if looking up Lambda metrics, 
        # BUT since we are now on K8s, old CloudWatch Lambda metrics won't apply to this new app directly
        # UNLESS we are still monitoring the old Lambda.
        # For transition, we will return empty or mock data, or look up specific metrics if defined.
        # Let's assume we want to view the OLD Lambda's metrics for now until we add Prometheus.
        
        function_name = "VisitorCounterFunction"
        
        invocations = cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Invocations',
            Dimensions=[{'Name': 'FunctionName', 'Value': function_name}],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Sum']
        )
        
        latency = cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Duration',
            Dimensions=[{'Name': 'FunctionName', 'Value': function_name}],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Average']
        )
        
        def sort_points(points):
            return sorted(points, key=lambda x: x['Timestamp'])

        sorted_invocations = sort_points(invocations['Datapoints'])
        sorted_latency = sort_points(latency['Datapoints'])

        total_invocations = sum(item['Sum'] for item in sorted_invocations)
        
        if sorted_latency:
            avg_duration = sum(item['Average'] for item in sorted_latency) / len(sorted_latency)
        else:
            avg_duration = 0.0
            
        chart_data = []
        for point in sorted_latency:
            chart_data.append({
                'timestamp': point['Timestamp'].isoformat(),
                'value': point['Average']
            })

        return {
            'invocations': sorted_invocations,
            'latency': sorted_latency,
            'total_invocations': total_invocations,
            'avg_duration': avg_duration,
            'chart_data': chart_data
        }

    except Exception as e:
        print(f"Metrics Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/visitor")
def update_visitor(data: VisitorAction):
    try:
        action = data.action
        if action == 'download':
            update_expression = "SET #d = if_not_exists(#d, :start) + :inc"
            expression_attribute_names = {'#d': 'downloads'}
        else:
            update_expression = "SET #v = if_not_exists(#v, :start) + :inc"
            expression_attribute_names = {'#v': 'views'}

        table.update_item(
            Key={'id': 'visitor_stats'},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues={
                ':inc': 1,
                ':start': 0
            },
            ReturnValues="UPDATED_NEW"
        )
        
        final_item = table.get_item(Key={'id': 'visitor_stats'})
        item = final_item.get('Item', {})
        
        views_count = int(item.get('views', item.get('count', 0)))
        downloads_count = int(item.get('downloads', 0))

        return {
            'views': views_count,
            'downloads': downloads_count
        }

    except Exception as e:
        print(f"DB Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
