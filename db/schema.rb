Sequel.migration do
  change do
    create_table(:http_requests) do
      column :id, "uuid", :default=>Sequel::LiteralString.new("uuid_generate_v4()"), :null=>false
      column :scheme, "character varying(255)"
      column :userinfo, "text"
      column :host, "text"
      column :port, "integer"
      column :path, "text"
      column :query, "text"
      column :fragment, "text"
      column :method, "character varying(255)"
      column :response_status, "integer"
      column :duration, "integer"
      column :started_at, "timestamp without time zone"
      
      primary_key [:id]
    end
    
    create_table(:schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end
  end
end
