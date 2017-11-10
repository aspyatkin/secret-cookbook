# secret cookbook
Managing secrets in Chef recipes.

## Usage

```ruby
secret = ::ChefCookbook::Secret::Helper.new(node)
secret.get('postgres:password:root')  # supersecretpassword
```

## Approach
If you use Chef [encrypted data bags](https://docs.chef.io/data_bags.html) for storing secrets (passwords, API keys etc.), you might have written some code like this below:

```ruby
secret_val = data_bag_item(DATA_BAG_NAME, DATA_BAG_ITEM_NAME)[SUBKEY_1][SUBKEY_2][SUBKEY_3]
```

Assuming you have several servers (Chef nodes) and various environments (development, staging, production), the scheme below is good enough for managing secrets for all assets in one repository:

1. `DATA_BAG_NAME` stands for a category. E.g. `postgres` for stroring all PostgreSQL server user passwords.
2. `DATA_BAG_ITEM_NAME` stands for an environment. E.g. `staging`.
3. `SUBKEY_1` (in fact, all top-level keys within JSON associated with a particular data bag item) stands for server (Chef node) FQDN.

With that in mind, the `postgres::staging` data bag item JSON will contain the following data:

```json
{
  "id": "staging",
  "db1.example.com": {
    "password": {
      "root": "reallystrongpassword1"
    }
  },
  "db2.example.com": {
    "password": {
      "reallystrongpassword2"
    }
  }
}
```

In order to obtain the necessary password while provisioning server `db1.example.com`, you can write in your recipe:

```ruby
postgres_pwd = data_bag_item('postgres', node.chef_environment)[node['automatic']['fqdn']]['password']['root']
```

`secret` cookbook will make the difference:

```ruby
secret = ::ChefCookbook::Secret::Helper.new(node)  # initialize once in a recipe
postgres_pwd = secret.get('postgres:password:root')
```

You only need to pass `DATA_BAG_NAME` and subkeys, excluding environment and FQDN values (they are detected automatically).

## Advanced usage

```ruby
secret_val = secret.get(query, options)
```

where `query` is a string and `options` is a Ruby Hash.

### `default` option
`secret.get` will return a default value in case there is no one defined in a data bag item.

### `required` option
Whether a value **must** be defined in a data bag item or by a `default` option. By default is `true`. A provision process will fail if a `required` value is not defined in a data bag item and there is no `default` value.

### `item` option
Overrides `DATA_BAG_ITEM_NAME`. By default it equals `node.chef_environment`.

### `prefix_fqdn` option
Whether or not prepend server (Chef node) FQDN to the query. By default is `true`. When the value is `false`, your data bag item JSON should look like this:

```json
{
  "id": "staging",
  "password": {
    "root": "reallystrongpassword1"
  }
}
```

This may be suitable for environments with a single node or several nodes with shared secrets.

Not only can this option be customised in a `server.get` call, but it may also be changed globally with `node['secret']['prefix_fqdn']` attribute (`true` by default).

### Examples

```ruby
val1 = secret.get('postgres:password:user', default: nil)
val2 = secret.get('aws:s3:access_key', prefix_fqdn: false)
```

## License
MIT @ [Alexander Pyatkin](https://github.com/aspyatkin)
