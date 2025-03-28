variable "Privsub1" {
  type = string
}

variable "Privsub2" {
  type = string
}
variable "alb_tg_arn" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}
 variable "execution_role_arn" {
   type = string
 }

variable "task_role_arn" {
  type = string
}

variable "ecs_listener" {
  type = string
}