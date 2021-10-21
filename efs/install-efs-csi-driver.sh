elm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade --install -f ./myvalues.yaml aws-efs-csi-driver --namespace kube-system aws-efs-csi-driver/aws-efs-csi-driver