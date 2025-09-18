'use strict';

const AWS = require('aws-sdk'); // v2 is available in Lambda runtime
const { randomUUID } = require('crypto');
const uuidv4 = () => randomUUID();

const dynamodb = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME;

function ok(body, statusCode = 200) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  };
}

function noContent() {
  return {
    statusCode: 204,
    headers: { 'Content-Type': 'application/json' },
    body: '',
  };
}

function badRequest(msg) {
  return {
    statusCode: 400,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ error: msg }),
  };
}

function unauthorized() {
  return {
    statusCode: 401,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ error: 'Unauthorized' }),
  };
}

exports.handler = async (event) => {
  try {
    // HTTP API v2 (payload v2)
    const method = event.requestContext?.http?.method || event.httpMethod;
    const path = event.requestContext?.http?.path || event.path;
    const claims = event.requestContext?.authorizer?.jwt?.claims;
    const userId = claims?.sub;

    // CORS preflight
    if (method === 'OPTIONS') {
      return {
        statusCode: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Authorization,Content-Type',
          'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        },
        body: '',
      };
    }

    if (!userId) return unauthorized();

    let body = {};
    if (event.body) {
      try {
        body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
      } catch (e) {
        return badRequest('Invalid JSON body');
      }
    }

    // ROUTING
    if (method === 'POST' && path === '/tasks') {
      const taskId = uuidv4();
      const { taskDescription } = body;
      if (!taskDescription || typeof taskDescription !== 'string') {
        return badRequest('taskDescription is required (string)');
      }
      const item = {
        userId,
        taskId,
        taskDescription,
        completed: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      await dynamodb.put({ TableName: TABLE_NAME, Item: item }).promise();
      return ok(item, 201);
    }

    if (method === 'GET' && path === '/tasks') {
      const res = await dynamodb.query({
        TableName: TABLE_NAME,
        KeyConditionExpression: 'userId = :u',
        ExpressionAttributeValues: { ':u': userId },
      }).promise();
      // sort by createdAt desc
      const items = (res.Items || []).sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
      return ok(items);
    }

    // PUT /tasks/{taskId}
    if (method === 'PUT' && path.startsWith('/tasks/')) {
      const taskId = event.pathParameters?.taskId || path.split('/')[2];
      if (!taskId) return badRequest('taskId required in path');
      const { taskDescription, completed } = body;

      const expressions = [];
      const values = {};
      if (typeof taskDescription === 'string') {
        expressions.push('taskDescription = :d');
        values[':d'] = taskDescription;
      }
      if (typeof completed === 'boolean') {
        expressions.push('completed = :c');
        values[':c'] = completed;
      }
      expressions.push('updatedAt = :u');
      values[':u'] = new Date().toISOString();

      if (Object.keys(values).length === 1) {
        return badRequest('Provide taskDescription and/or completed to update');
      }

      await dynamodb.update({
        TableName: TABLE_NAME,
        Key: { userId, taskId },
        UpdateExpression: 'SET ' + expressions.join(', '),
        ExpressionAttributeValues: values,
      }).promise();

      return ok({ taskId });
    }

    // DELETE /tasks/{taskId}
    if (method === 'DELETE' && path.startsWith('/tasks/')) {
      const taskId = event.pathParameters?.taskId || path.split('/')[2];
      if (!taskId) return badRequest('taskId required in path');

      await dynamodb.delete({
        TableName: TABLE_NAME,
        Key: { userId, taskId },
      }).promise();

      return noContent();
    }

    return badRequest(`Unsupported route: ${method} ${path}`);
  } catch (err) {
    console.error(err);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Internal Server Error', detail: String(err && err.message || err) }),
    };
  }
};

// Tiny uuid fallback if layer/pkg not present (Lambda Node18 includes AWS SDK v2, not uuid)
function uuidv4() {
  // RFC4122 v4 quick generator
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = (Math.random() * 16) | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
