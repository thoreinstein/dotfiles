_:
{
  # Everything only the work machine needs. Lists and attrs merge into the shared modules.
  mcpServers = {
    jira = {
      type = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
    };
    glean = {
      type = "http";
      url = "https://pingidentity-be.glean.com/mcp/default";
    };
    firehydrant = {
      type = "stdio";
      command = "bash";
      args = [
        "-c"
        ''exec npx -y firehydrant-mcp@0.0.4 start --transport stdio --api-key "$FIREHYDRANT_API_KEY"''
      ];
    };
  };
}
