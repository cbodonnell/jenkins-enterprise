-include .env

ifeq ($(VERSION),)
	VERSION := $(shell git rev-parse --short HEAD)
	ifneq ($(shell git status --porcelain),)
		VERSION := $(VERSION)-dirty
	endif
endif

deps:
	helm repo add jenkins https://charts.jenkins.io
	helm repo update

download: deps
	helm pull jenkins/jenkins --untar --untardir=jenkins --ov

container:
	docker build -t cheebz/jenkins:$(VERSION) .

push: container
	docker push cheebz/jenkins:$(VERSION)

ttl.sh: container
	docker tag cheebz/jenkins:$(VERSION) ttl.sh/cheebz/jenkins:$(VERSION)
	docker push ttl.sh/cheebz/jenkins:$(VERSION)

values:
	VERSION=$(VERSION) \
	envsubst < values.yaml.tmpl > values.yaml

deploy: deps values
	helm upgrade jenkins-enterprise jenkins/jenkins -i \
	-n jenkins-enterprise --create-namespace \
	-f values.yaml

admin-password:
	kubectl exec --namespace jenkins-enterprise -it svc/jenkins-enterprise -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo

port-forward:
	kubectl port-forward svc/jenkins-enterprise -n jenkins-enterprise 8080:8080

clean:
	rm -f values.yaml
	rm -rf jenkins
	rm -f jenkins-*.tgz
