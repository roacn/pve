<a id="top"></a>

![proxmox](img/proxmox.png)

- [1 安装curl、wget、squashfs-tools工具](#artical_1)
- [2 PVE一键换源、去订阅等](#artical_2)
- [3 LXC容器OpenWrt安装、更新](#artical_3)
  - [3.1 OpenWrt安装、更新](#artical_3.1)
  - [3.2 Fullconenat安装（可选）](#artical_3.2)

------

<br />
<a id="artical_1"></a>

### 1 安装curl、wget、squashfs-tools工具

---

使用root用户登录，执行以下命令

```shell
apt update && apt install -y curl wget squashfs-tools
```

<br />
<a id="artical_2"></a>

### 2 PVE一键换源、去订阅等

---

温馨提示：

> 以下请在`PVE命令行`中操作

<br />


- [x] 方式一：PVE中输入以下命令安装pve.sh，然后在PVE命令行中直接输入 **`pve`** 运行 **推荐**

>  国内网络

```shell
wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/pve.sh -O /usr/sbin/pve && chmod +x /usr/sbin/pve
```

> 国外网络

```shell
wget https://raw.githubusercontent.com/roacn/pve/main/pve.sh -O /usr/sbin/pve && chmod +x /usr/sbin/pve
```

完成以上操作，以后在PVE命令行中输入 **`pve`** 命令即可运行脚本

<br />

- [x] 方式二：直接运行

>  国内网络

```shell
bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/pve.sh)"
```

>  国外网络

```shell
bash -c  "$(curl -fsSL https://raw.githubusercontent.com/roacn/pve/main/pve.sh)"
```

![pve.png](img/pve.png)



<br />

<br />
<a id="artical_3"></a>

### 3 LXC容器OpenWrt安装、更新

---

<br />
<a id="artical_3.1"></a>

### 3.1 OpenWrt安装、更新

> 以下请在`PVE命令行`中运行！

<br />

- [x] 方式一：PVE中直接使用 `openwrt`  命令运行自动安装更新脚本 **推荐**

>  国内网络

```shell
wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/sbin/openwrt && chmod +x /usr/sbin/openwrt
```

> 国外网络

```shell
wget https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/sbin/openwrt && chmod +x /usr/sbin/openwrt
```

通过以上操作，openwrt.lxc.sh即被下载至/usr/sbin/openwrt以后，在PVE命令行中输入 `openwrt` 运行脚本，进行安装或更新操作！

<br />


- [x] 方式二：直接运行

>  国内网络

```shell
bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh)"
```

> 国外网络

```shell
bash -c  "$(curl -fsSL https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh)"
```

完成！

<br />
<a id="artical_3.2"></a>

### 3.2 Fullconenat安装（可选）


>` 如果不需要开FullCone-NAT（全锥形NAT），可直接忽略。`
>
>为LXC容器的OpenWrt提供FullCone-NAT（全锥形NAT）
>
>以下请在`PVE命令行`中运行！

<br />

#### 3.2.1 安装pve-headers、dkms

命令：

```shell
apt update
apt install pve-headers-`uname -r` -y
apt install dkms -y
```

<br />

#### 3.2.2 安装[netfilter-fullconenat-dkms-git](https://github.com/roacn/pve/blob/main/lxc/netfilter-fullconenat-dkms-git.tar.gz)

命令：

```shell
cd /tmp && wget https://github.com/roacn/pve/blob/main/lxc/netfilter-fullconenat-dkms-git.tar.gz
tar -xvf netfilter-fullconenat-dkms-git.tar.gz -C /usr/src
dkms install -m netfilter-fullconenat-dkms -v git
```

<br />

#### 3.2.3 检查是否安装成功

命令：

```shell
dkms status
```

结果如下表示dkms已经安装成功

```shell
root@pve:~# dkms status
netfilter-fullconenat-dkms, git, 5.13.19-3-pve, x86_64: installed
```

命令：

```shell
modinfo xt_FULLCONENAT
```

结果如下表示xt_FULLCONENAT已经安装成功

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

<br />

#### 3.2.4 旧版内核卸载

> `后期更新fullconenat时使用，首次安装fullconenat忽略此步`

<br />

查看当前已经安装的 netfilter-fullconenat-dkms

命令：

```shell
dkms status
```

运行结果如下

```shell
root@pve:~# dkms status
netfilter-fullconenat-dkms, git, 5.15.30-1-pve, x86_64: installed
netfilter-fullconenat-dkms, git, 5.15.35-1-pve, x86_64: installed
```

<br />

卸载旧版内核netfilter-fullconenat-dkms

命令：

```shell
dkms remove netfilter-fullconenat-dkms -v <Version> -k <Kernel>
```

如果想删除netfilter-fullconenat-dkms, git, 5.15.30-1-pve, x86_64: installed

那么，\<Version>对应上面的git，\<Kernel>对应上面的5.15.30-1-pve

运行结果如下

```
root@pve:~# dkms remove netfilter-fullconenat-dkms -v git -k 5.15.30-1-pve

-------- Uninstall Beginning --------
Module:  netfilter-fullconenat-dkms
Version: git
Kernel:  5.15.30-1-pve (x86_64)
-------------------------------------

Status: Before uninstall, this module version was ACTIVE on this kernel.

xt_FULLCONENAT.ko:
 - Uninstallation
   - Deleting from: /lib/modules/5.15.30-1-pve/updates/dkms/
 - Original module
   - No original module was found for this module on this kernel.
   - Use the dkms install command to reinstall any previous module version.

depmod....
DKMS: uninstall completed.
------------------------------
Deleting module version: git
completely from the DKMS tree.
------------------------------
Done.
```

通过以上操作`/var/lib/dkms/netfilter-fullconenat-dkms/`目录下的`旧版netfilter-fullconenat-dkms`即可卸载删除。



<br />
<br />


![openwrt11.png](img/openwrt11.png)

![openwrt12.png](img/openwrt12.png)

![openwrt13.png](img/openwrt13.png)

![openwrt2.png](img/openwrt2.png)

![openwrt31.png](img/openwrt31.png)

![openwrt32.png](img/openwrt32.png)

![openwrt4.png](img/openwrt4.png)

![openwrt5.png](img/openwrt5.png)



[返回顶部](#top)
