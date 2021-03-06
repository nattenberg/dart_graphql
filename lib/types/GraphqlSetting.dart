// Copyright (c) 2019, the Black Salt authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:json_object_lite/json_object_lite.dart';

import '../dart_graphql.dart';

GraphqlBuildSetting createSetting(
        {String schemaUrl,
        String method = "post",
        bool postIntrospectionQuery = true,
        String schemaFile}) =>
    GraphqlBuildSetting(schemaUrl, method, postIntrospectionQuery, schemaFile);

class GraphqlBuildSetting {
  String schemaUrl;
  String method;
  bool postIntrospectionQuery;

  String schemaFile;

  GraphqlBuildSetting(this.schemaUrl, this.method, this.postIntrospectionQuery,
      this.schemaFile);

  JsonObjectLite<dynamic> _schemaObject;

  Future getSchema() async {
    if (_schemaObject == null) {
      if (schemaFile != null) {
        var fileContent = await File(schemaFile).readAsString();
        _schemaObject = JsonObjectLite<dynamic>.fromJsonString(fileContent);
      } else if (schemaUrl != null) {
        var client = RestClient(schemaUrl);
        JsonResponse result;
        if (method == "post") {
          Map<String, dynamic> query = <String, dynamic>{};
          if (postIntrospectionQuery) {
            query = <String, dynamic>{"query": introspectionQuery};
          }
          result = await client.postJson("", query);
        } else {
          result = await client.getJson("", <String, dynamic>{});
        }
        dynamic decoded =
            result.decode((d) => JsonObjectLite<dynamic>.fromJsonString(d))
                as dynamic;
        _schemaObject = decoded.data.__schema as JsonObjectLite<dynamic>;
      }
    }
    return _schemaObject;
  }

  static const String introspectionQuery = """
     query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }

  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }

  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }

  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
  """;
}
