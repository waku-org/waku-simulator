FROM python:3.11-alpine

WORKDIR /app

# Install system packages needed by the script
RUN apk add --no-cache bind-tools jq

# Install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy scripts
COPY init_node_tokens.py .
COPY get_account_key.sh .

# Make scripts executable
RUN chmod +x /app/init_node_tokens.py /app/get_account_key.sh

# Use the account key helper as entrypoint
ENTRYPOINT ["/bin/sh", "/app/get_account_key.sh"]