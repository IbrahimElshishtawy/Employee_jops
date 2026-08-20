import * as fs from 'fs';
import * as path from 'path';
import * as http from 'http';

interface SwaggerSpec {
  info: {
    title: string;
    description: string;
    version: string;
  };
  paths: Record<string, Record<string, any>>;
  components?: {
    schemas?: Record<string, any>;
  };
}

http.get('http://127.0.0.1:3000/api/docs-json', (res) => {
  let data = '';
  res.on('data', (chunk) => (data += chunk));
  res.on('end', () => {
    try {
      const spec: SwaggerSpec = JSON.parse(data);
      generatePostman(spec);
    } catch (e) {
      console.error('Failed to parse OpenAPI JSON:', e);
    }
  });
}).on('error', (err) => {
  console.error('Error fetching swagger docs:', err);
});

function resolveSchema(schema: any, schemas: Record<string, any>): any {
  if (!schema) return {};
  if (schema.$ref) {
    const refName = schema.$ref.replace('#/components/schemas/', '');
    return resolveSchema(schemas[refName], schemas);
  }
  if (schema.type === 'object' || schema.properties) {
    const obj: Record<string, any> = {};
    if (schema.properties) {
      for (const key of Object.keys(schema.properties)) {
        const prop = schema.properties[key];
        if (prop.example !== undefined) {
          obj[key] = prop.example;
        } else if (prop.default !== undefined) {
          obj[key] = prop.default;
        } else if (prop.$ref) {
          obj[key] = resolveSchema(prop, schemas);
        } else if (prop.type === 'string') {
          if (prop.format === 'date-time') obj[key] = new Date().toISOString();
          else if (prop.enum) obj[key] = prop.enum[0];
          else if (key.toLowerCase().includes('email')) obj[key] = 'admin@example.test';
          else if (key.toLowerCase().includes('password')) obj[key] = 'Test@123456';
          else obj[key] = `sample_${key}`;
        } else if (prop.type === 'number' || prop.type === 'integer') {
          obj[key] = prop.default ?? 0;
        } else if (prop.type === 'boolean') {
          obj[key] = prop.default ?? true;
        } else if (prop.type === 'array') {
          obj[key] = [];
        } else {
          obj[key] = null;
        }
      }
    }
    return obj;
  }
  return {};
}

function generatePostman(spec: SwaggerSpec) {
  const schemas = spec.components?.schemas || {};

  const collection: any = {
    info: {
      name: 'CyberWise IE — Backend API Collection',
      description: spec.info.description || 'Collection for CyberWise IE Backend APIs',
      schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      _exporter_id: 'cyberwise-automation',
    },
    auth: {
      type: 'bearer',
      bearer: [
        {
          key: 'token',
          value: '{{accessToken}}',
          type: 'string',
        },
      ],
    },
    event: [
      {
        listen: 'prerequest',
        script: {
          type: 'text/javascript',
          exec: [''],
        },
      },
      {
        listen: 'test',
        script: {
          type: 'text/javascript',
          exec: [''],
        },
      },
    ],
    variable: [
      {
        key: 'baseUrl',
        value: 'http://127.0.0.1:3000/api/v1',
        type: 'string',
      },
      {
        key: 'accessToken',
        value: '',
        type: 'string',
      },
      {
        key: 'refreshToken',
        value: '',
        type: 'string',
      },
    ],
    item: [],
  };

  const tagFolders: Record<string, any[]> = {};

  for (const [routePath, methods] of Object.entries(spec.paths)) {
    for (const [method, op] of Object.entries(methods)) {
      if (typeof op !== 'object' || !op.summary) continue;

      const tag = (op.tags && op.tags[0]) || 'General';
      if (!tagFolders[tag]) {
        tagFolders[tag] = [];
      }

      // Convert /api/v1/auth/login into {{baseUrl}}/auth/login
      const normalizedPath = routePath.replace(/^\/api\/v1/, '');
      const pathSegments = normalizedPath.split('/').filter((s) => s.length > 0);

      // Handle path variables like {id} -> :id
      const postmanPathSegments = pathSegments.map((segment) => {
        if (segment.startsWith('{') && segment.endsWith('}')) {
          return `:${segment.slice(1, -1)}`;
        }
        return segment;
      });

      const urlObj: any = {
        raw: `{{baseUrl}}${normalizedPath.replace(/\{([^}]+)\}/g, ':$1')}`,
        host: ['{{baseUrl}}'],
        path: postmanPathSegments,
        variable: [],
        query: [],
      };

      // Query parameters and path params
      if (op.parameters) {
        for (const param of op.parameters) {
          if (param.in === 'path') {
            urlObj.variable.push({
              key: param.name,
              value: param.schema?.default || 'sample-id',
              description: param.description || '',
            });
          } else if (param.in === 'query') {
            urlObj.query.push({
              key: param.name,
              value: param.schema?.default !== undefined ? String(param.schema.default) : '',
              description: param.description || '',
              disabled: !param.required,
            });
          }
        }
      }

      // Request Body
      let requestBody: any = undefined;
      if (op.requestBody?.content?.['application/json']?.schema) {
        const bodySchema = op.requestBody.content['application/json'].schema;
        const resolvedBody = resolveSchema(bodySchema, schemas);
        requestBody = {
          mode: 'raw',
          raw: JSON.stringify(resolvedBody, null, 2),
          options: {
            raw: {
              language: 'json',
            },
          },
        };
      }

      // Test Script (Auto-save tokens for Login)
      const postmanEvents: any[] = [];
      if (routePath.includes('/auth/login')) {
        postmanEvents.push({
          listen: 'test',
          script: {
            type: 'text/javascript',
            exec: [
              '// Auto-set JWT access and refresh tokens into environment variables',
              'const res = pm.response.json();',
              'if (res.data && res.data.tokens) {',
              '    pm.collectionVariables.set("accessToken", res.data.tokens.accessToken);',
              '    pm.collectionVariables.set("refreshToken", res.data.tokens.refreshToken);',
              '    console.log("Tokens saved to collection variables successfully!");',
              '} else if (res.tokens) {',
              '    pm.collectionVariables.set("accessToken", res.tokens.accessToken);',
              '    pm.collectionVariables.set("refreshToken", res.tokens.refreshToken);',
              '}',
            ],
          },
        });
      }

      const requestItem: any = {
        name: op.summary || `${method.toUpperCase()} ${normalizedPath}`,
        request: {
          method: method.toUpperCase(),
          header: [
            {
              key: 'Content-Type',
              value: 'application/json',
              type: 'text',
            },
          ],
          url: urlObj,
          description: op.description || '',
        },
        response: [],
      };

      if (requestBody) {
        requestItem.request.body = requestBody;
      }

      if (postmanEvents.length > 0) {
        requestItem.event = postmanEvents;
      }

      tagFolders[tag].push(requestItem);
    }
  }

  for (const [tag, items] of Object.entries(tagFolders)) {
    collection.item.push({
      name: tag,
      item: items,
    });
  }

  // Write files
  const collectionFilePath = path.join(__dirname, '../CyberWise_IE_API.postman_collection.json');
  fs.writeFileSync(collectionFilePath, JSON.stringify(collection, null, 2), 'utf-8');
  console.log(`✅ Generated Postman Collection: ${collectionFilePath}`);

  const environment = {
    id: 'cyberwise-local-env',
    name: 'CyberWise IE — Local Environment',
    values: [
      {
        key: 'baseUrl',
        value: 'http://127.0.0.1:3000/api/v1',
        type: 'default',
        enabled: true,
      },
      {
        key: 'accessToken',
        value: '',
        type: 'secret',
        enabled: true,
      },
      {
        key: 'refreshToken',
        value: '',
        type: 'secret',
        enabled: true,
      },
      {
        key: 'adminEmail',
        value: 'admin@example.test',
        type: 'default',
        enabled: true,
      },
      {
        key: 'adminPassword',
        value: 'Test@123456',
        type: 'secret',
        enabled: true,
      },
    ],
    _postman_variable_scope: 'environment',
    _exporter_id: 'cyberwise-automation',
  };

  const envFilePath = path.join(__dirname, '../CyberWise_IE_Local.postman_environment.json');
  fs.writeFileSync(envFilePath, JSON.stringify(environment, null, 2), 'utf-8');
  console.log(`✅ Generated Postman Environment: ${envFilePath}`);
}
