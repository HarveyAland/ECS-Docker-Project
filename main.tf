provider "aws" {
  region = "eu-west-2"
}

module "vpc" {
  source = "./modules/vpc"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}


module "iam" {
  source = "./modules/iam"
}

module "ecr_ecs" {
  source             = "./modules/ecr_ecs"
  alb_tg_arn         = module.alb.alb_tg_arn
  ecs_sg_id          = module.security.ecs_sg_id
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  Privsub1           = module.vpc.Privsub1
  Privsub2           = module.vpc.Privsub2
  ecs_listener       = module.alb.ecs_listener
}

module "alb" {
  source = "./modules/alb"
  Pubsub1    = module.vpc.Pubsub1
  vpc_id     = module.vpc.vpc_id
  sg_id      = module.security.ecs_sg_id
  Pubsub2    = module.vpc.Pubsub2
}