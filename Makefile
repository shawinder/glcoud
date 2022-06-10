PROJECT=dev-machine-352317
REGION=us-west1
INSTANCE=dev-machine-vm
IP_NAME=dev-machine-ip
FIREWALL_HTTP=allow-http
FIREWALL_HTTPS=allow-https
TAG_HTTP=http-server
TAG_HTTPS=https-server
create_ip:
	gcloud compute addresses create ${IP_NAME} \
	--project=${PROJECT} \
	--network-tier=STANDARD \
	--region=${REGION}
export_ip:
	$(eval IP_ADDRESS:=$(shell gcloud compute addresses list \
	--filter="name:dev-machine-ip AND region:us-west1" \
	--format="value(address_range())"))
show_ip:
	@echo ${IP_ADDRESS}
firewall_http:
	gcloud compute firewall-rules create ${FIREWALL_HTTP} \
	--project=${PROJECT} \
	--direction=INGRESS \
	--network=default \
	--action=ALLOW \
	--rules=tcp:80 \
	--source-ranges=0.0.0.0/0 \
	--target-tags=${TAG_HTTP}
firewall_https:
	gcloud compute firewall-rules create ${FIREWALL_HTTPS} \
	--project=${PROJECT} \
	--direction=INGRESS \
	--network=default \
	--action=ALLOW \
	--rules=tcp:443 \
	--source-ranges=0.0.0.0/0 \
	--target-tags=${TAG_HTTPS}
create_instance: export_ip
	gcloud compute instances create ${INSTANCE} \
	--scopes=cloud-platform \
	--project=${PROJECT} \
	--zone=${REGION}-b \
	--machine-type=n1-standard-1 \
	--preemptible \
	--image=ubuntu-1804-bionic-v20220530 \
	--image-project=ubuntu-os-cloud \
	--boot-disk-size=10GB \
	--boot-disk-type=pd-standard \
	--boot-disk-device-name=${INSTANCE} \
	--metadata-from-file startup-script=vm/dev-machine.sh \
	--network-tier=STANDARD \
	--address=${IP_ADDRESS} \
	--subnet=default \
	--tags=${TAG_HTTP},${TAG_HTTPS} \
	--labels=os=ubuntu-18-04-lts,cost-alloc=${INSTANCE},usage=development,configuration=v1-1-0
run: create_ip export_ip firewall_http firewall_https create_instance
ssh:
	gcloud compute ssh --zone "${REGION}-b" "${INSTANCE}"  --project "${PROJECT}"
cleanup:
	gcloud --quiet compute instances delete ${INSTANCE} --zone=${REGION}-b
	gcloud --quiet compute addresses delete ${IP_NAME} --region=${REGION}
	gcloud --quiet compute firewall-rules delete ${FIREWALL_HTTP}
	gcloud --quiet compute firewall-rules delete ${FIREWALL_HTTPS}
