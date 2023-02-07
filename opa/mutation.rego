package system

import data.kubernetes.namespaces

############################################################
# PATCH rules 
#
# Note: All patch rules should start with `isValidRequest` and `isCreateOrUpdate`
############################################################

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "Pod"
    hasLabel(input.request.object, "needs-lustre")
	patchCode = makeAnnotationPatch("add", "openpolicyagent.org/configured", "true", "")
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "Pod"
    hasLabel(input.request.object, "needs-lustre")
	patchCode = {
		"op": "add",
		"path": "/spec/securityContext/runAsUser",
		"value": to_number(namespaces[input.request.namespace].metadata.annotations["runAsUser"]),
	}
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "Pod"
    hasLabel(input.request.object, "needs-lustre")
	patchCode = {
		"op": "add",
		"path": "/spec/securityContext/runAsGroup",
		"value": to_number(namespaces[input.request.namespace].metadata.annotations["runAsGroup"]),
	}
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "Pod"
    hasLabel(input.request.object, "needs-lustre")
	patchCode = {
		"op": "add",
		"path": "/spec/volumes/-",
		"value": {
            "name": "lustre",
            "hostPath": {
                "path": "/var/lustre",
                "type": "Directory"
            }
        },
	}
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "Pod"
    hasLabel(input.request.object, "needs-lustre")
	patchCode = {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
            "name": "lustre",
            "mountPath": "/lustre"
        },
	}
}
