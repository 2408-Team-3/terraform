Decisions:
 -we'll be implementing API keys
 -need to configure gateway to require api key in header
 -need to correlate api key to useage plan

API Gateway Method (POST method for sending requests)
each http method associated with an endpoint is considered a separate resource:

    resource "aws_api_gateway_method" "post_errors" {
      rest_api_id   = aws_api_gateway_rest_api.api.id # API Gateway id from above
      resource_id   = aws_api_gateway_resource.endpoint.id # API Gateway endpoitn from above
      http_method   = "POST"
      authorization = "NONE" # allows our SDKs to send error data without authentication tokens or IAM permissions
    }

If we leave authorization as none, there's no limit on the type of requests that can come in (easier setup but
greater security risk). Leaves architecture open to DOS attacks.

if this is left as none, we should be sure to use rate limiting and validation of request data

the better alternative is to generate api keys (store in secrets manager?), provide them to the users/include
key in each request from the sdk: (user would get a new key each time they create a new project? we could
  format the request with a variable and instruct user to save it as an env variable?):

in sdk: (also , api gateway url needs to be passed at instantiation)
const apiKey = 'your_api_key_here'; // Replace with the actual API key var
fetch('https://your-api-gateway-url.amazonaws.com/api/errors', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'flytrap-api-key': apiKey, // Include the API key in the headers
  },
  body: JSON.stringify({
    error: 'Sample error message',
  }),
});

on TF end, provision api key resource and usage plan, require key in the post method config above

when backend generates a new api key (when a new project is created), it needs to register the api
key with the corresponding api gateway:

 def associate_api_key_with_usage_plan(api_key_id, usage_plan_id):
    client = boto3.client('apigateway')  # Create a client to interact with API Gateway
    client.create_usage_plan_key(          # Call the API to associate the key with the usage plan
        usagePlanId=usage_plan_id,         # ID of the usage plan with which to associate the key
        keyId=api_key_id,                  # ID of the API key to be associated
        keyType='API_KEY'                  # Specify that the type of key being associated is an API key
    )

api gateway must be configured to accept multiple keys

ideally, a user should always have the option to generate a new api key (if they suspect theirs has been exposed/compromised. For this, each project would need a button to generate new key. The user would need to swap the key in their .env file. and we'd need to re-run the above funtion
to add the new key to the api gateway AND somehow get the previous/existing key and remove it from
the api gateway)

alternatives:
 - whitelist user's ips
 - use a token (shared secret) in request headers. makes it much harder for unauthorized users to send requests
