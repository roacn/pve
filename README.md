

### 安装curl、wget、squashfs-tools工具

使用root用户登录，执行以下命令

```shell
apt update && apt install -y curl wget squashfs-tools
```



### 设置中文语言包

命令行

```shell
dpkg-reconfigure locales → [ * ] en_US.UF8
```

文件编译

```shell
/etc/locale.gen去除en_US.UF8前面#
运行locale-gen
```

重启PVE即可



### PVE一键换源、去订阅等

> 以下请在PVE命令行中运行！




- [x] PVE中直接使用`pve`命令

国内网络

```shell
wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/pve.sh -O /usr/sbin/pve && chmod +x /usr/sbin/pve
```

国外网络

```shell
wget https://raw.githubusercontent.com/roacn/pve/main/pve.sh -O /usr/sbin/pve && chmod +x /usr/sbin/pve
```

即可在PVE命令行中使用`pve`运行脚本



- [x] 直接运行

国内网络

```shell
bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/pve.sh)"
```

国外网络

```shell
bash -c  "$(curl -fsSL https://raw.githubusercontent.com/roacn/pve/main/pve.sh)"
```

![pve.png](https://raw.githubusercontent.com/roacn/pve/main/img/pve.png)



### Fullconenat安装

> 以下请在PVE命令行中运行！
>
> 为LXC容器的OpenWrt提供FullCone-NAT（全锥形NAT）



- [x] 软件下载

[netfilter-fullconenat-dkms-git](https://github.com/roacn/pve/blob/main/lxc/netfilter-fullconenat-dkms-git.tar.gz)



- [x] 软件安装

ssh至PVE，运行以下命令

```shell
apt update
apt install pve-headers-`uname -r` -y
apt install dkms -y
```



- [x] 解压netfilter-fullconenat-dkms-git.tar.gz

```shell
tar -xvf netfilter-fullconenat-dkms-git.tar.gz -C /usr/src
```



- [x] 安装netfilter-fullconenat-dkms-git.tar.gz

```shell
dkms install -m netfilter-fullconenat-dkms -v git
```



- [x] 检查是否安装成功

运行`dkms status`

```shell
root@pve:~# dkms status
netfilter-fullconenat-dkms, git, 5.13.19-3-pve, x86_64: installed
```

运行`modinfo xt_FULLCONENAT`

```shell
root@pve:~# modinfo xt_FULLCONENAT
filename:       /lib/modules/5.13.19-3-pve/updates/dkms/xt_FULLCONENAT.ko
alias:          ipt_FULLCONENAT
author:         Chion Tang <tech@chionlab.moe>
description:    Xtables: implementation of RFC3489 full cone NAT
license:        GPL
srcversion:     CE0EBE32D25F6F43D755D2E
depends:        x_tables,nf_nat,nf_conntrack
retpoline:      Y
name:           xt_FULLCONENAT
vermagic:       5.13.19-3-pve SMP mod_unload modversions 
```

出现如上信息，说明fullconenat已经安装成功，OpenWrt在防火墙内开启fullconenat，重启PVE生效。



- [x] 旧版内核卸载

检查已经安装的`netfilter-fullconenat-dkms`

```shell
root@pve:~# dkms status
netfilter-fullconenat-dkms, git, 5.10.0-11-amd64, x86_64: installed
netfilter-fullconenat-dkms, git, 5.10.0-12-amd64, x86_64: installed
```



卸载旧版内核`netfilter-fullconenat-dkms`

```shell
dkms remove netfilter-fullconenat-dkms -v <Version> -k <Kernel>
```



```
root@pve:~# dkms remove netfilter-fullconenat-dkms -v git -k 5.10.0-12-amd64

-------- Uninstall Beginning --------
Module:  netfilter-fullconenat-dkms
Version: git

Kernel:  5.10.0-12-amd64 (x86_64)
-------------------------------------

Status: Before uninstall, this module version was ACTIVE on this kernel.

xt_FULLCONENAT.ko:

 - Uninstallation
   - Deleting from: /lib/modules/5.10.0-12-amd64/updates/dkms/
 - Original module
   - No original module was found for this module on this kernel.
   - Use the dkms install command to reinstall any previous module version.

depmod...

DKMS: uninstall completed.

------------------------------

Deleting module version: git

completely from the DKMS tree.
------------------------------

Done.
```

通过以上操作`/var/lib/dkms/netfilter-fullconenat-dkms/`目录下的旧版`netfilter-fullconenat-dkms`即可卸载删除。



### LXC容器OpenWrt安装、更新

> 以下请在PVE命令行中运行！

> 如果PVE网络下载固件比较慢，经常更新可把PVE的网关、DNS指向OpenWrt，懂的都懂！


- [x] PVE中直接使用`openwrt`命令运行自动安装更新脚本

国内网络

```shell
wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/sbin/openwrt && chmod +x /usr/sbin/openwrt
```

国外网络

```shell
wget https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/sbin/openwrt && chmod +x /usr/sbin/openwrt
```

即可在PVE命令行中使用`openwrt`运行脚本




- [x] 直接运行

国内网络

```shell
bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh)"
```

国外网络

```shell
bash -c  "$(curl -fsSL https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh)"
```

![openwrt11.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt11.png)

![openwrt12.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt12.png)

![openwrt13.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt13.png)

![openwrt2.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt2.png)

![openwrt31.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt31.png)

![openwrt32.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt32.png)

![openwrt4.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt4.png)

![openwrt5.png](https://raw.githubusercontent.com/roacn/pve/main/img/openwrt5.png)
