# before deploying
docker login quay.io
gcloud auth login

docker-compose up -d prometheus grafana 

# MEET THIS PROBLEM: error getting credentials - err: exit status 1, out: ''
# In ~/.docker/config.json change credsStore to credStore
