import unittest
import json
import boto3
import os
from moto import mock_aws
from lambda_function import lambda_handler

@mock_aws
class TestVisitorCounter(unittest.TestCase):
    def setUp(self):
        """Set up DynamoDB mock table before each test"""
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        self.table_name = 'VisitorCounter'
        os.environ['TABLE_NAME'] = self.table_name
        
        self.table = self.dynamodb.create_table(
            TableName=self.table_name,
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )

    def test_view_increment(self):
        """Test that a view event increments the view count"""
        event = {
            'body': json.dumps({'action': 'view'})
        }
        
        # First call
        response = lambda_handler(event, None)
        body = json.loads(response['body'])
        
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(body['views'], 1)
        self.assertEqual(body['downloads'], 0)
        
        # Second call
        response = lambda_handler(event, None)
        body = json.loads(response['body'])
        self.assertEqual(body['views'], 2)

    def test_download_increment(self):
        """Test that a download event increments the download count"""
        event = {
            'body': json.dumps({'action': 'download'})
        }
        
        response = lambda_handler(event, None)
        body = json.loads(response['body'])
        
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(body['views'], 0)
        self.assertEqual(body['downloads'], 1)

    def test_cors_headers(self):
        """Test that CORS headers are returned"""
        event = {}
        response = lambda_handler(event, None)
        
        headers = response['headers']
        self.assertEqual(headers['Access-Control-Allow-Origin'], '*')
        self.assertIn('Content-Type', headers)

    def test_options_method(self):
        """Test OPTIONS method handling for CORS preflight"""
        event = {
            'requestContext': {
                'http': {
                    'method': 'OPTIONS'
                }
            }
        }
        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 200)

if __name__ == '__main__':
    unittest.main()
