import json
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

def lambda_handler(event, context):
    body = json.loads(event['body'])

    name = body['name']
    email = body['email']

    user_id = str(uuid.uuid4())

    table.put_item(
        Item={
            'userId': user_id,
            'name': name,
            'email': email
        }
    )

    return {
        'statusCode': 200,
        'body': json.dumps('User registered successfully')
    }