module "module_rg" {

  source = "../../Modules/Resource-group"
  rg     = var.dev_module_rg

}



module "module_storageaccount" {
  depends_on = [module.module_rg] #explicit dependency (block k name per lgti h)
  source     = "../../Modules/storage-account"
  storacc    = var.dev_module_storacc

}



module "module_vnet" {

  depends_on = [module.module_rg]

  source = "../../Modules/vnet"
  vnet   = var.dev_module_vnet

}



module "module_subnet" {

  depends_on = [module.module_rg, module.module_vnet]

  source = "../../Modules/subnet"
  subnet = var.dev_module_subnet
}

