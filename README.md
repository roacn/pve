<a id="top"></a>

![proxmox](img/proxmox.png)

- [1 安装curl、wget、squashfs-tools工具](#artical_1)
- [2 PVE一键换源、去订阅等](#artical_2)
- [3 LXC容器OpenWrt安装、更新](#artical_3)

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

```shell
wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/pve.sh -O /usr/bin/pve && chmod +x /usr/bin/pve
```

完成以上操作，以后在PVE命令行中输入 **`pve`** 命令即可运行脚本

<br />

- [x] 方式二：直接运行

```shell
bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/pve.sh)"
```

![pve.png](img/pve.png)



<br />

<br />
<a id="artical_3"></a>

### 3 LXC容器OpenWrt安装、更新

---

<br />

> 以下请在`PVE命令行`中运行！

<br />

- [x] 方式一：PVE中直接使用 `openwrt`  命令运行自动安装更新脚本 **推荐**

```shell
wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/bin/openwrt && chmod +x /usr/bin/openwrt
```

通过以上操作，openwrt.lxc.sh即被下载至/usr/bin/openwrt以后，在PVE命令行中输入 `openwrt` 运行脚本，进行安装或更新操作！

<br />


- [x] 方式二：直接运行

```shell
bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh)"
```

完成！



<br />
<br />

[返回顶部](#top)
