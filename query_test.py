import urllib.request
import json
import os

token = "ghp_FAKE" # Not needed for public if not querying viewer but wait we need a token for GraphQL. Let's see if we can use an unauthenticated way or just assume it's `replyTo`.
