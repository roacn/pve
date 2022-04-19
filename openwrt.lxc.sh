#!/bin/bash
# URL: https://github.com/roacn/build-actions
# Description: AutoUpdate for Openwrt
# Author: Ss.
# Please use the PVE command line to run the shell script.
# 个人Github地址（自行更改）
export Apidz="roacn/build-actions"
# release的tag名称（自行更改）
export Tag_Name="AutoUpdate-lxc"
# 固件搜索正则表达式（自行更改）
export Firmware_Regex="[0-9]+\.[0-9]+.*?rootfs.*?\.img\.gz"
export Github_API="https://api.github.com/repos/${Apidz}/releases/tags/${Tag_Name}"
export Release_Download_URL="https://github.com/${Apidz}/releases/download/${Tag_Name}"
export Openwrt_Path="/tmp/openwrt"
export Download_Path="/tmp/openwrt/download"
export Creatlxc_Path="/tmp/openwrt/creatlxc"
export Backup_Path="/tmp/openwrt/backup"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export Version="2022.03.22"
# pause
pause(){
    read -n 1 -p " Press any key to continue... " input
    if [[ -n ${input} ]]; then
        echo -e "\b\n"
    fi
}
# 字体颜色设置
TIME(){
[[ -z "$1" ]] && {
    echo -ne " "
} || {
    case $1 in
    r) export Color="\e[31;1m";;
    g) export Color="\e[32;1m";;
    b) export Color="\e[34;1m";;
    y) export Color="\e[33;1m";;
    z) export Color="\e[35;1m";;
    l) export Color="\e[36;1m";;
    esac
    [[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
    }
}
# 更新OpenWrt CT模板I
release_chose(){
    echo
    releases=`egrep -o "${Firmware_Regex}" ${Download_Path}/Github_Tags | uniq`
    TIME g "Github云端固件"
    echo "${releases}"
    if [[ -z ${releases} ]]; then
        TIME r "当前云端固件列表为空，请检查！"
        exit 0
    fi
    choicesnum=`echo "${releases}" | wc -l`
    while :; do
        read -t 30 -p " 请选择要下载的固件[n，默认n=1，即倒数第1个最新固件]：" release
        release=${release:-1}
        n0=`echo ${release} | sed 's/[0-9]//g'`
        if [[ ! -z $n0 ]]; then
            TIME r "输入错误，请输入数字！"
        elif [[ ${release} -eq 0 ]] || [[ ${release} -gt ${choicesnum} ]]; then
            TIME r "输入超出范围，请重新输入！"
        else
            echo "${releases}" | tail -n ${release} | head -n 1 > ${Download_Path}/DOWNLOAD_URL
            TIME g "下载固件：$(cat ${Download_Path}/DOWNLOAD_URL)"
            break
        fi
    done
}
# 更新OpenWrt CT模板II
update_CT_Templates(){
    [[ ! -d ${Download_Path} ]] && mkdir -p ${Download_Path} || rm -rf ${Download_Path}/*
    echo
    TIME y "下载OpenWrt固件"
    echo
    TIME g "正在检测网络..."
    export Google_Check=$(curl -I -s --connect-timeout 5 google.com -w %{http_code} | tail -n1)
    [[ "$Google_Check" == 301 ]] && echo " ${Google_Check}：即将直连github.com下载！" || echo " ${Google_Check}：即将通过代理下载！"
    echo
    TIME g "获取固件API信息..."
    if [ ! "$Google_Check" == 301 ];then
        wget -q --timeout=5 --tries=2 --show-progress https://ghproxy.com/${Release_Download_URL}/Github_Tags -O ${Download_Path}/Github_Tags
        if [[ $? -ne 0 ]];then
            wget -q --timeout=5 --tries=2 --show-progress https://pd.zwc365.com/${Release_Download_URL}/Github_Tags -O ${Download_Path}/Github_Tags
            if [[ $? -ne 0 ]];then
                TIME r "获取固件API信息失败，请检测网络，或者网址是否正确！"
                echo
                exit 1
            else
                TIME g "获取固件API信息成功！"
            fi
        else
            TIME g "获取固件API信息成功！"
        fi
    else
        wget -q --timeout=5 --tries=2 --show-progress ${Github_API} -O ${Download_Path}/Github_Tags
        if [[ $? -ne 0 ]];then
            TIME r "获取固件API信息失败，请检测网络，或者网址是否正确！"
            echo
            exit 1
        else
            TIME g "获取固件API信息成功！"
        fi
    fi
    release_chose
    [ -s ${Download_Path}/DOWNLOAD_URL ] && {
    if [ ! "$Google_Check" == 301 ];then
        echo " 通过https://ghproxy.com/代理下载固件中..."
        wget -q --timeout=5 --tries=2 --show-progress https://ghproxy.com/${Release_Download_URL}/$(cat ${Download_Path}/DOWNLOAD_URL) -O ${Download_Path}/openwrt.rootfs.img.gz
        if [[ $? -ne 0 ]];then
            echo " 通过https://pd.zwc365.com/代理下载固件中..."
            wget -q --timeout=5 --tries=2 --show-progress https://pd.zwc365.com/${Release_Download_URL}/$(cat ${Download_Path}/DOWNLOAD_URL) -O ${Download_Path}/openwrt.rootfs.img.gz
            if [[ $? -ne 0 ]];then
                TIME r "固件下载失败，请检测网络，或者网址是否正确！"
                echo
                exit 1
            else
                TIME g "固件镜像：下载成功！"
            fi
        else
            TIME g "固件镜像：下载成功！"
        fi
    else
        wget -q --timeout=5 --tries=2 --show-progress ${Release_Download_URL}/$(cat ${Download_Path}/DOWNLOAD_URL) -O ${Download_Path}/openwrt.rootfs.img.gz
        if [[ $? -ne 0 ]];then
            TIME r "获取固件失败，请检测网络，或者网址是否正确！"
            echo
            exit 1
        else
            TIME g "固件镜像：下载成功"
        fi
    fi
    }
    imgsize=`ls -l ${Download_Path}/openwrt.rootfs.img.gz | awk '{print $5}'`
    TIME g "固件镜像：${imgsize}字节"
    echo
    TIME y "更新OpenWrt CT模板"
    echo
    TIME g "解包OpenWrt img镜像..."
    cd ${Download_Path} && gzip -d openwrt.rootfs.img.gz && unsquashfs openwrt.rootfs.img
    TIME g "CT模板：上传至/var/lib/vz/template/cache目录..."
    if [[ -f /var/lib/vz/template/cache/openwrt.rootfs.tar.gz ]]; then
        rm -f /var/lib/vz/template/cache/openwrt.rootfs.tar.gz
    fi
    cd ${Download_Path}/squashfs-root && tar zcf /var/lib/vz/template/cache/openwrt.rootfs.tar.gz ./* && cd ../.. && rm -rf ${Download_Path}
    TIME g "CT模板：上传成功！"
    ctsize=`ls -l /var/lib/vz/template/cache/openwrt.rootfs.tar.gz | awk '{print $5}'`    
    TIME g "CT模板：${ctsize}字节"
}
# 容器ID
pct_id(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt容器ID[默认100]：" id || echo
        id=${id:-100}
        n1=`echo ${id} | sed 's/[0-9]//g'`
        if [[ ! -z $n1 ]]; then
            TIME r "输入错误，请重新输入！"
        elif [[ ${id} -lt 100 ]]; then
            TIME r "当前输入ID<100，请重新输入！"
        else
            break
        fi
    done
}
# 容器名称
pct_hostname(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt容器名称[默认OpenWrt]：" hostname || echo
        hostname=${hostname:-OpenWrt}
        n2=`echo ${hostname} | sed 's/[a-zA-Z0-9]//g' | sed 's/[.-_]//g'`
        if [[ ! -z $n2 ]]; then
            TIME r "输入错误，请重新输入！"
        else
            break
        fi
    done
}
# 分区大小
pct_rootfssize(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt分区大小[GB，默认2]：" rootfssize || echo
        rootfssize=${rootfssize:-2}
        n3=`echo ${rootfssize} | sed 's/[0-9]//g'`
        if [[ ! -z $n3 ]]; then
            TIME r "输入错误，请重新输入！"
        elif [[ ${rootfssize} == 0 ]]; then
            TIME r "不能为0，请重新输入！"
        else
            break
        fi
    done
}
# CPU核心数
pct_cores(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt CPU核心数[默认4]：" cores || echo
        cores=${cores:-4}
        n4=`echo ${cores} | sed 's/[0-9]//g'`
        if [[ ! -z $n4 ]]; then
            TIME r "输入错误，请重新输入！"
        elif [[ ${cores} == 0 ]]; then
            TIME r "不能为0，请重新输入！"
        else
            break
        fi
    done
}
# 内存大小
pct_memory(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt内存大小[MB，默认2048]：" memory || echo
        memory=${memory:-2048}
        n5=`echo ${memory} | sed 's/[0-9]//g'`
        if [[ ! -z $n5 ]]; then
            TIME r "输入错误，请重新输入！"
        elif [[ ${memory} == 0 ]]; then
            TIME r "不能为0，请重新输入！"
        else
            break
        fi
    done
}
# 开机自启
pct_onboot(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt是否开机自启[0关闭，1开启，默认1]：" onboot || echo
        onboot=${onboot:-1}
        case ${onboot} in
        0)
            order=2
            break
        ;;
        1)
            pct_order
            break
        ;;
        *)
            TIME r "输入错误，请重新输入！"
        ;;
        esac
    done
}
# 启动顺序
pct_order(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt启动顺序[默认2]：" order || echo
        order=${order:-2}
        n6=`echo ${order} | sed 's/[0-9]//g'`
        if [[ ! -z $n6 ]]; then
            TIME r "输入错误，请重新输入！"
        elif [[ ${order} == 0 ]]; then
            TIME r "不能为0，请重新输入！"
        else
            break
        fi
    done
}
# 网络接口设置
pct_net(){
    echo
    while :; do
        read -t 30 -p " 请输入OpenWrt网络接口数量[n取1-4，vmbr0为PVE自带，其它需在PVE网络中创建，默认1]：" net || echo
        net=${net:-1}
        case ${net} in
        1)
            cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
		pct create ${id} \\
		local:vztmpl/openwrt.rootfs.tar.gz \\
		--rootfs local-lvm:${rootfssize} \\
		--ostype unmanaged \\
		--hostname ${hostname} \\
		--arch amd64 \\
		--cores ${cores} \\
		--memory ${memory} \\
		--swap 0 \\
		--net0 bridge=vmbr0,name=eth0 \\
		--unprivileged 0 \\
		--features nesting=1 \\
		--onboot ${onboot} \\
		--startup order=${order}
		EOF
            break
        ;;
        2)
            cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
		pct create ${id} \\
		local:vztmpl/openwrt.rootfs.tar.gz \\
		--rootfs local-lvm:${rootfssize} \\
		--ostype unmanaged \\
		--hostname ${hostname} \\
		--arch amd64 \\
		--cores ${cores} \\
		--memory ${memory} \\
		--swap 0 \\
		--net0 bridge=vmbr0,name=eth0 \\
		--net1 bridge=vmbr1,name=eth1 \\
		--unprivileged 0 \\
		--features nesting=1 \\
		--onboot ${onboot} \\
		--startup order=${order}
		EOF
            break
        ;;
        3)
            cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
		pct create ${id} \\
		local:vztmpl/openwrt.rootfs.tar.gz \\
		--rootfs local-lvm:${rootfssize} \\
		--ostype unmanaged \\
		--hostname ${hostname} \\
		--arch amd64 \\
		--cores ${cores} \\
		--memory ${memory} \\
		--swap 0 \\
		--net0 bridge=vmbr0,name=eth0 \\
		--net1 bridge=vmbr1,name=eth1 \\
		--net2 bridge=vmbr2,name=eth2 \\
		--unprivileged 0 \\
		--features nesting=1 \\
		--onboot ${onboot} \\
		--startup order=${order}
		EOF
            break
        ;;
        4)
            cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
		pct create ${id} \\
		local:vztmpl/openwrt.rootfs.tar.gz \\
		--rootfs local-lvm:${rootfssize} \\
		--ostype unmanaged \\
		--hostname ${hostname} \\
		--arch amd64 \\
		--cores ${cores} \\
		--memory ${memory} \\
		--swap 0 \\
		--net0 bridge=vmbr0,name=eth0 \\
		--net1 bridge=vmbr1,name=eth1 \\
		--net2 bridge=vmbr2,name=eth2 \\
		--net3 bridge=vmbr3,name=eth3 \\
		--unprivileged 0 \\
		--features nesting=1 \\
		--onboot ${onboot} \\
		--startup order=${order}
		EOF
            break
        ;;
        *)
            TIME r "输入错误，请重新输入！"
        ;;
        esac
    done
    if [[ -n `ls /dev/disk/by-id | grep "${id}--disk"` ]]; then
        cat > ${Creatlxc_Path}/destroy_openwrt <<-EOF
	pct destroy ${id} --destroy-unreferenced-disks 1 --purge 1 --force 1
	EOF
    fi
}
# 创建lxc容器I
creat_lxc_openwrt1(){
    echo
    [[ ! -d ${Creatlxc_Path} ]] && mkdir -p ${Creatlxc_Path} || rm -rf ${Creatlxc_Path}/*
    TIME y "开始创建OpenWrt lxc容器"
    pct_id
    pct_hostname
    pct_rootfssize
    pct_cores
    pct_memory
    pct_onboot
    pct_net
}
# 创建lxc容器II
creat_lxc_openwrt2(){
    configrecovery=n
    while :; do
        read -t 30 -p " 是否保留OpenWrt配置？[y/Y或n/N，默认y]：" configbackup || echo
        configbackup=${configbackup:-y}
        case ${configbackup} in
        y|Y)
            echo
            openwrtstatus=`pct status ${id} | awk '{print $2}'`
            case ${openwrtstatus} in
            running)
                TIME g "正在备份配置..."
                config_backup
                configrecovery=y
            ;;
            stopped)
                TIME g "OpenWrt处于关机状态，马上为您开机！"
                start_openwrt
                TIME g "正在备份配置..."
                config_backup
                configrecovery=y
            ;;
            *)
                TIME r "容器不存在，无需备份！"
            ;;
            esac
            break
        ;;
        n|N)
            break
        ;;
        *)
            TIME r "输入错误，请重新输入！"
        ;;
        esac
    done
    echo
    if [[ -f ${Creatlxc_Path}/destroy_openwrt ]]; then
        TIME r "${id}容器已经存在！"
        while :; do
            read -t 30 -p " 是否删除${id}容器，然后继续？[y/Y或n/N，默认y]：" creatlxc || echo
            creatlxc=${creatlxc:-y}
            case ${creatlxc} in
            y|Y)
                echo
                TIME g "正在删除${id}容器..."
                bash ${Creatlxc_Path}/destroy_openwrt
                break
            ;;
            n|N)
                menu
                break
            ;;
            *)
                TIME r "输入错误，请重新输入！"
            ;;
            esac
        done
    fi
    [[ -f ${Creatlxc_Path}/creat_openwrt ]] && echo && TIME g "正在创建新容器..." && bash ${Creatlxc_Path}/creat_openwrt && echo && TIME g "lxc容器OpenWrt创建成功！" || TIME r "pct命令不存在或执行错误！"
    [[ ${configrecovery} == y ]] && start_openwrt && config_recovery
}
# 备份OpenWrt设置
config_backup(){
    [[ ! -d ${Backup_Path} ]] && mkdir -p ${Backup_Path} || rm -rf ${Backup_Path}/*
    pct pull ${id} /etc/sysupgrade.conf ${Backup_Path}/sysupgrade.conf
    while read line; do
        linehead=`echo "${line}" | cut -c 1`
        if [[ ${linehead} == "/" ]]; then
            back_file=${Backup_Path}${line}
            echo " 备份OpenWrt：${line}"
            [[ ! -d ${Backup_Path}`dirname "${line}"` ]] && mkdir -p ${Backup_Path}`dirname "${line}"`
            pct pull ${id} ${line} ${back_file}
        fi
    done < ${Backup_Path}/sysupgrade.conf
}
# 启动OpenWrt
start_openwrt(){
    echo
    TIME g "启动OpenWrt，请耐心等待约1分钟..."
    sleep 5
    pct start ${id}
    sleep 30
    t=0
    while :; do
        let t+=1
        pct exec ${id} -- ping -c 2 www.baidu.com
        if [[ $? -ne 0 ]] && [[ ${t} -le 5 ]]; then                
            echo " OpenWrt启动中... 10s后进行第${t}次尝试！"
            sleep 10
        elif [[ $? -ne 0 ]] && [[ ${t} -gt 5 ]]; then
            TIME r "OpenWrt启动失败！请手动启动后继续！"
            echo
            pause
            t=0
        else
            TIME g "OpenWrt启动成功！"
            break
        fi
    done
}
# 恢复OpenWrt设置
config_recovery(){
    echo
    TIME g "开始恢复配置..."
    while read line; do
        linehead=`echo "${line}" | cut -c 1`
        if [[ ${linehead} == "/" ]]; then
            rec_file=${Backup_Path}${line}
            if [[ -f ${rec_file} ]]; then
                echo " 恢复OpenWrt：${line}"
                pct push ${id} ${rec_file} ${line}
                if [[ $? -ne 0 ]]; then
                    echo " 恢复${line}失败！"
                else
                    echo " 恢复${line}成功！"
                fi
            else
                echo " ${line}不存在！"
            fi
        fi
    done < ${Backup_Path}/sysupgrade.conf
    TIME g "恢复配置完成！"
}
# 安装工具
install_tools(){
    echo
    TIME y "检测脚本依赖..."
    pve_pkgs="curl wget squashfs-tools"
    apt update
    for i in ${pve_pkgs}; do
        if [[ $(apt list --installed | grep -o "^${i}\/" | wc -l) -ge 1 ]]; then
            TIME g "${i} 已安装"
        else
            TIME r "${i} 未安装"
            TIME g "开始安装${i} ..."
            apt install -y ${i}
        fi
    done
}
# 清空文件
clean_files(){
    [[ -d ${Openwrt_Path} ]] && rm -rf ${Openwrt_Path}
}
# 帮助
onekey_help() {
    clear
    cat <<-EOF
    =============================================================================================

    `TIME y "1. 固件编译"`

        1)编译前
        make meunconfig --> targert images --> 选中[ * ] GZip images
        2)编译后
        将xxx.rootfs.img.gz上传至release

    ---------------------------------------------------------------------------------------------

    `TIME y "2. 脚本修改"`

        # 个人Github地址（自行更改）
        export Apidz="xxx/xxx"
        # release的tag名称（自行更改）
        export Tag_Name="xxx"
        # 固件搜索正则表达式（自行更改）
        例如：固件名称为18.06-lede-x86-64-lxc-202203032218-rootfs-66afdf.img.gz，则可设置如下
        export Firmware_Regex="18\.06.*?rootfs.*?\.img\.gz"

    ---------------------------------------------------------------------------------------------

    `TIME y "3. 网络接口"`

        网络接口数量>1时，需自建网络接口。
        网络接口数量1：无需创建，使用系统默认vmbr0；
        网络接口数量2：vmbr1；
        网络接口数量3：vmbr1、vmbr2；
        网络接口数量4：vmbr1、vmbr2、vmbr3。

    ---------------------------------------------------------------------------------------------

    `TIME y "4. 设置保存"`

        a. 需要保留的配置，请将文件路径存放在OpenWrt系统/etc/sysupgrade.conf文件中，格式如下：
            ## This file contains files and directories that should
            ## be preserved during an upgrade.
            /etc/config/passwall
            
           注：在此文件结尾请保留一行空白行！
        b. 云编译时，可将sysupgrade.conf文件存放在/build/xxx/files/etc目录下。

    =============================================================================================
EOF
}
# 检测脚本运行环境
linux_uname(){
    ver=`uname -a | grep -i "Linux pve"`
    if [[ -z ${ver} ]]; then
        clear
        echo " `uname -a`"
        echo
        TIME r "脚本需运行在PVE环境，检测当前非PVE环境！"
        echo
        echo " ────────────────────────────────────────────────────────────────────────────"
        echo
        echo " PVE运行："
        TIME g "pct pull xxx /sbin/openwrt.lxc /usr/sbin/openwrt && chmod +x /usr/sbin/openwrt"
        echo " 注意：将xxx改为个人OpenWrt容器的ID，如100"
        echo
        echo " PVE运行："
        TIME g "openwrt"
        echo
        echo " ────────────────────────────────────────────────────────────────────────────"
        echo
        exit 0
    fi
}
# 主菜单
menu(){
    clear
    #[[ ! -d ${Openwrt_Path} ]] && mkdir -p ${Openwrt_Path}
    echo
    cat <<-EOF
`TIME y "     OpenWrt自动安装升级脚本  v${Version}"`
┌──────────────────────────────────────────┐
     安    1. 更新CT模板 + 创建LXC容器
     装    2. 更新CT模板
     更    3. 创建LXC容器
     新    4. 检测依赖工具
 ──────────────────────────────────────────
           5. 帮助
           0. 退出
└──────────────────────────────────────────┘
EOF
    echo -ne " 请选择: [ ]\b\b"
    read -t 60 menuid
    menuid=${menuid:-0}
    case ${menuid} in
    1)
        update_CT_Templates
        creat_lxc_openwrt1
        echo
        creat_lxc_openwrt2
        echo
        TIME y "10s后，将清理残留文件..."
        sleep 10
        clean_files
        echo
        pause
        menu
    ;;
    2)
        update_CT_Templates
        echo
        pause
        menu
    ;;
    3)
        creat_lxc_openwrt1
        echo
        creat_lxc_openwrt2
        echo
        pause
        menu
    ;;
    4)
        install_tools
        echo
        pause
        menu
    ;;
    5)
        onekey_help
        echo
        pause
        menu
    ;;
    0)
        clean_files
        clear
        exit 0
    ;;
    *)
        menu
    ;;
    esac
}
# 脚本运行！
linux_uname
menu
