# Hyper-V  Switch

## Static Switch IP Address

在Hyper-V虚拟交换机管理器中创建新的虚拟交换机并设置为内部网络。

在控制面板中的**更改适配器**设置中，为创建的交换机分配静态IP



## VMSwitch Nat Configuration

设定为**内部**的虚拟交换机无法访问外网，为其设置NAT，[参考链接](https://learn.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/user-guide/setup-nat-network)。

```shell
# Windows Powershell
Get-NetAdapter
```

```shell
PS C:\Users\Bryce> Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
ZeroTier One [e77308c5... ZeroTier Virtual Port                        28 Up           A6-DC-CC-0B-EA-98       100 Mbps
VMware Network Adapte...8 VMware Virtual Ethernet Adapter for ...      26 Up           00-50-56-C0-00-08       100 Mbps
vEthernet (StaticSwitch)  Hyper-V Virtual Ethernet Adapter #2          17 Up           00-15-5D-01-67-0A        10 Gbps
VMware Network Adapte...1 VMware Virtual Ethernet Adapter for ...      16 Up           00-50-56-C0-00-01       100 Mbps
以太网 2                  SecTap Adapter                               13 Disconnected 00-FF-3E-1D-51-A7         1 Gbps
Tailscale                 Tailscale Tunnel                             56 Up                                   100 Gbps
WLAN                      Intel(R) Wi-Fi 6E AX211 160MHz               10 Up           D4-E9-8A-19-FA-37       1.2 Gbps
蓝牙网络连接              Bluetooth Device (Personal Area Netw...       8 Disconnected D4-E9-8A-19-FA-3B         3 Mbps
以太网                    Realtek Gaming 2.5GbE Family Controller       4 Up           00-E2-69-77-08-B5         1 Gbps
```

找到刚刚创建的交换机的索引。

#### 使用 [New-NetIPAddress](https://learn.microsoft.com/zh-cn/powershell/module/nettcpip/New-NetIPAddress) 配置 NAT 网关

```shell
New-NetIPAddress -IPAddress <NAT Gateway IP> -PrefixLength <NAT Subnet Prefix Length> -InterfaceIndex <ifIndex>
```

```shell
New-NetIPAddress -IPAddress 172.16.1.1 -PrefixLength 24 -InterfaceIndex 17
```

网关地址要与交换机地址一致。

#### 使用 [New-NetNat](https://learn.microsoft.com/zh-cn/powershell/module/netnat/New-NetNat) 配置 NAT 网络。

设置网络名称和网段。

```shell
New-NetNat -Name <NATOutsideName> -InternalIPInterfaceAddressPrefix <NAT subnet prefix>
```

```shell
New-NetNat -Name HyperVNATNEt -InternalIPInterfaceAddressPrefix 172.16.1.0/24
```

查看NAT网络

```shell
Get-NetNat
```

```shell
PS C:\Users\Bryce> Get-NetNat


Name                             : HyperVNatNet
ExternalIPInterfaceAddressPrefix :
InternalIPInterfaceAddressPrefix : 172.16.0.0/24
IcmpQueryTimeout                 : 30
TcpEstablishedConnectionTimeout  : 1800
TcpTransientConnectionTimeout    : 120
TcpFilteringBehavior             : AddressDependentFiltering
UdpFilteringBehavior             : AddressDependentFiltering
UdpIdleSessionTimeout            : 120
UdpInboundRefresh                : False
Store                            : Local
Active                           : True
```

