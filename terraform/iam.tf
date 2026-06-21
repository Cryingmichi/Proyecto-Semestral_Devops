# En AWS Academy Learner Lab no es posible crear roles IAM nuevos
# (la cuenta no tiene permisos iam:CreateRole). Por eso reutilizamos
# el rol "LabRole" que el laboratorio ya provee con los permisos
# necesarios para ECS (pull de imágenes desde ECR, envío de logs a
# CloudWatch, etc.). Se usa tanto como execution role como task role.

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
