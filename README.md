```sh
PROJECT=dev-machine-352317
REGION=us-west1
INSTANCE=dev-machine-vm
IP_NAME=dev-machine-ip
FIREWALL_HTTP=allow-http
FIREWALL_HTTPS=allow-https
TAG_HTTP=http-server
TAG_HTTPS=https-server

gcloud compute addresses create $IP_NAME \
 --project=$PROJECT \
 --network-tier=STANDARD \
 --region=$REGION

gcloud compute addresses list

IP_ADDRESS=$(gcloud compute addresses list \
 --filter="name:$IP_NAME AND region:$REGION" \
 --format="value(address_range())"
 )

gcloud compute firewall-rules create $FIREWALL_HTTP \
 --project=$PROJECT \
 --direction=INGRESS \
 --network=default \
 --action=ALLOW \
 --rules=tcp:80 \
 --source-ranges=0.0.0.0/0 \
 --target-tags=$TAG_HTTP
 
gcloud compute firewall-rules create $FIREWALL_HTTPS \
 --project=$PROJECT \
 --direction=INGRESS \
 --network=default \
 --action=ALLOW \
 --rules=tcp:443 \
 --source-ranges=0.0.0.0/0 \
 --target-tags=$TAG_HTTPS
 
wget https://raw.githubusercontent.com/shawinder/glcoud/main/vm/dev-machine.sh

gcloud compute instances create $INSTANCE \
 --project=$PROJECT \
 --zone=$REGION-b \
 --machine-type=n1-standard-1 \
 --preemptible \
 --image=ubuntu-1804-bionic-v20220530 \
 --image-project=ubuntu-os-cloud \
 --boot-disk-size=10GB \
 --boot-disk-type=pd-standard \
 --boot-disk-device-name=$INSTANCE \
 --metadata-from-file startup-script=dev-machine.sh \
 --network-tier=STANDARD \
 --address=$IP_ADDRESS \
 --subnet=default \
 --tags=$TAG_HTTP,$TAG_HTTPS \
 --labels=os=ubuntu-18-04-lts,cost-alloc=$INSTANCE,usage=development,configuration=v1-1-0
``` 
- Go to `Google Console -> instance -> ssh` (open up a new popup terminal) and run following:
```sh
sudo groupadd chrome-remote-desktop
sudo usermod -a -G chrome-remote-desktop $USER
logout
```

- Go to https://remotedesktop.google.com/headless and follow instructions:
	- Copy debian command text
	- Open `Google Console -> instance -> ssh` (open up a new popup terminal)
	- Run the previously copied debian code
	- logout
	
- Access the VM using https://remotedesktop.google.com/access

- Cleanup Resources
```sh
gcloud compute instances delete $INSTANCE --zone=$REGION-b
gcloud compute addresses delete $IP_NAME --region=$REGION
gcloud compute firewall-rules delete $FIREWALL_HTTP
gcloud compute firewall-rules delete $FIREWALL_HTTPS
```