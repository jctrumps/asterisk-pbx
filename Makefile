.PHONY: infra-init infra-plan infra-apply infra-destroy app deploy all check clean

infra-init:
	cd opentofu && tofu init

infra-plan:
	cd opentofu && tofu plan

infra-apply:
	cd opentofu && tofu apply

infra-destroy:
	cd opentofu && tofu destroy

app:
	cd ansible && ansible-galaxy collection install -r requirements.yml && ansible-playbook site.yml

deploy: infra-apply app

all: deploy

check:
	cd ansible && ansible-playbook site.yml --syntax-check

clean:
	rm -rf opentofu/.terraform
