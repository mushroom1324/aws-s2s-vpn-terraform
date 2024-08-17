AWS에서 하이브리드 네트워크를 구성하기 위해 Site-to-Site VPN connection 구성을 해야 할 수 있습니다. Site to Site VPN은 VPC와 온프레미스 간의 연결을 위해 사용하고, IPsec VPN 연결을 지원합니다.

**IPsec 연결을 하는 이유**

VPC와 온프레미스 간 전송에 있어서 Direct Connect같은 dedicated connection을 구성하지 않는 이상 필연적으로 Internet을 거쳐 통신해야 합니다. 그렇기에 데이터를 암호화하여 네트워크를 통해 전송되는 동안 데이터가 도청되거나 탈취되지 않도록 보호해야 합니다. IPsec은 데이터 암호화를 지원하여 안전한 데이터 통신이 가능하도록 도와줍니다.

**왜 Site-to-Site VPN이어야 하는가**

Site-to-Site VPN은 AWS에서 제공하는 관리형 VPN 서비스입니다. High Availability를 위해 두 개의 터널을 제공하여, 하나의 터널이 다운되어도 다른 하나의 터널로 트래픽을 연결할 수 있도록 도와줍니다. 또한 Site-to-Site VPN을 사용하면 CloudWatch를 통해 모니터링이 가능하여 다양한 시나리오에서 트러블슈팅을 할 수 있다는 점도 있습니다. 그리고 관리형 서비스이기 때문에 매뉴얼한 IPsec 구성보다 훨씬 간편하다는 점도 있습니다.

**Site-to-Site VPN 실습 환경 구축**

<img width="911" alt="s2s1" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/7bcfaa39-c9fe-4740-b374-bcec67cac331">

AWS Network - Customer Network의 Site-to-Site VPN 연결을 구성해보겠습니다. 다음을 위해선 실제 Customer Network가 필요하지만, 저희는 도쿄 리전에 있는 EC2 인스턴스로 Customer Network를 흉내내어 구성해보겠습니다. 기본적 환경 구성의 경우 테라폼 소스 코드를 공개해 두었으므로 이를 통해 손쉽게 구성 가능합니다.

**Routing Table**

AWS Network의 Routing Table에선 자신의 CIDR 범위인 10.0.0.0/16의 경우 Local을 향하도록 하고, Customer Network의 CIDR 범위인 192.168.0.0/16은 Vritual Private Gateway를 향하도록 설정합니다.

Customer Network의 Routing Table에선 자신의 CIDR 범위인 192.168.0.0/16의 경우 Local을 향하도록 하고, 그 외의 모든 범위 0.0.0.0/0에 대해선 Internet Gateway를 향하도록 설정합니다. Customer Network의 EC2-VPN은 온프레미스 환경의 엔드포인트인 Customer Router를 나타냅니다. 이는 인터넷을 거치도록 라우팅을 구성해야 합니다.

**Security Group**

EC2-A에서는 192.168.0.0/16의 ICMP 프로토콜을 허용하여, Ping 테스트를 가능하도록 구성합니다.

**테라폼으로 리소스 구성하기**

레포지토리 소스 파일을 이용하여 간단히 실습 환경을 구축할 수 있습니다. 그 전에 `aws configure` 명령어로 리소스를 생성할 환경을 정의합니다. 프로필 설정과 관련한 방법에 대해서는 [다음 문서를 참고하세요.](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

```
aws configure --profile s2s
```

`profile` 옵션을 지정하여 `s2s` 프로필에 엑세스 키 값을 입력합니다. 프로필 지정 후 다음과 같이 실행합니다:

```
terraform init
terraform apply
```

<img width="686" alt="s2s2" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/80351163-fd3a-4f83-9023-2c3529a3e485">

정상적으로 실행하였다면 다음과 같은 결과를 기대할 수 있습니다.

테라폼으로 환경 구성을 하고 싶지 않고, 직접 리소스를 만들고 싶다면 그렇게 하셔도 좋습니다. 상단 이미지를 토대로 리소스를 생성하시면 됩니다.

Site-to-Site VPN 연결 리소스를 정의하는 블럭은 다음과 같습니다:

``` terraform
# Site to Site VPN Connection
resource "aws_vpn_connection" "aws_vpn_connection" {
  provider            = aws.seoul
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.aws_customer_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true

  local_ipv4_network_cidr  = aws_vpc.customer_vpc.cidr_block
  remote_ipv4_network_cidr = aws_vpc.aws_vpc.cidr_block

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-vpn"
  }
}

# VPN Connection Route
resource "aws_vpn_connection_route" "aws_vpn_connection_route" {
  provider               = aws.seoul
  destination_cidr_block = aws_vpc.customer_vpc.cidr_block
  vpn_connection_id      = aws_vpn_connection.aws_vpn_connection.id
}
```

여기서 static_routes_only 를 false로 지정하면 BGP를 이용한 dynamic routing이 가능하도록 구성해야 합니다. 즉, Customer Gateway에서 BGP를 지원해야 하므로, 해당 실습에선 static_routes_only를 true 로 설정했습니다.

`local_ipv4_network_cidr` 을 aws_vpc의 cidr로 오해할 수 있습니다. 이에 주의해야 합니다.

Site to Site VPN 설정 후, AWS 콘솔을 통해 Customer VPC의 EC2에 사용할 VPN Configuration File을 다운로드합니다. 이 때 Vendor를 Openswan으로 선택합니다. (Libreswan은 Openswan의 포크입니다)

<img width="1440" alt="s2s3" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/6610e996-7145-4bcd-ae31-b7560e199cee">

<img width="1440" alt="s2s4" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/b522447f-9c9c-4544-a402-7b97805c2b55">

Configuration File 예시

이제 EC2에서 Libreswan을 구성합시다. AWS 매니지먼트 콘솔에서 Tokyo 리전의 EC2(Customer EC2)로 Instance Connect를 통해 접속합니다.

<img width="627" alt="s2s5" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/69a8bee7-87c7-4eb7-b1c7-bdf47325e6aa">

Amazon Linux 2023부터는 Openswan을 기본적으로 지원하지 않기 때문에, 추가적인 설정이 필요합니다. 먼저 레포지토리를 생성하고 Libreswan을 설치해야 합니다. 따라서 EC2에 접속했다면 다음 명령어를 통해 repo 파일을 생성해줍니다.

```bash
sudo vi /etc/yum.repos.d/fedora.repo
```

그 후 파일에서 다음의 내용을 붙여넣습니다:

```bash
[fedora]
name=Fedora 36 - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/36/Everything/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-36&arch=$basearch
enabled=0
countme=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=https://getfedora.org/static/fedora.gpg
skip_if_unavailable=False
```

붙여넣었다면 저장 후 나옵니다. (`!wq` 명령어나 `ZZ` 를 통해 저장 후 종료를 할 수 있습니다)

저장했다면 다음 명령어를 통해 Libreswan을 설치합니다.

```bash
sudo dnf --enablerepo=fedora install libreswan -y
```

<img width="1386" alt="s2s6" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/95af6147-efd1-45bf-b0a5-748172d2b133">

설치가 완료된 모습

Libreswan의 설치를 마쳤다면, systemctl configuration file을 수정합니다.

```bash
sudo vi /etc/sysctl.conf
```

해당 파일 하단에 다음의 명령어를 추가하고 마찬가지로 저장하고 나옵니다.

```bash
 net.ipv4.ip_forward = 1
 net.ipv4.conf.default.rp_filter = 0
 net.ipv4.conf.default.accept_source_route = 0
```

그 후 다음 명령어를 실행하여 변경사항을 반영합니다.

```bash
sudo sysctl -p
```

다음으로, /etc/ipsec.conf 파일을 열어 `include /etc/ipsec.d/*.conf` 엔트리가 있는지 확인합니다.

```bash
sudo vi /etc/ipsec.conf
```

<img width="1401" alt="s2s7" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/87fc9508-777d-4be2-a15a-e435b822f092">

마지막줄에 제대로 설정되어 있는 것을 확인하였으므로 추가적 작업이 필요하지 않습니다. 만약 #로 주석 처리되어 있다면 주석을 해제합니다.

이제 미리 다운받았던 VPN Configuration File의 스텝을 따라갑니다. 4번부터 보겠습니다.

4) Create a new file at /etc/ipsec.d/aws.conf if doesn't already exist:

```bash
sudo vi /etc/ipsec.d/aws.conf
```

다음과 같은 내용을 붙여넣습니다. **(본인의 configuration file 안의 내용을 집어넣습니다)**

```bash
conn Tunnel1
	authby=secret
	auto=start
	left=%defaultroute
	leftid=18.176.25.8
	right=3.37.114.133
	type=tunnel
	ikelifetime=8h
	keylife=1h
	phase2alg=aes128-sha1;modp1024
	ike=aes128-sha1;modp1024
	auth=esp
	keyingtries=%forever
	keyexchange=ike
	leftsubnet=<LOCAL NETWORK>
	rightsubnet=<REMOTE NETWORK>
	dpddelay=10
	dpdtimeout=30
	dpdaction=restart_by_peer
```

몇가지 바꿔야 할 점이 있습니다.

1. `auth=esp` 라인을 삭제합니다. 이건 Libreswan에서 지원하지 않습니다.
2. `phase2alg` 을 `aes_gcm` 값으로 변경합니다.
3. `ike` 을 `aes256-sha1` 값으로 변경합니다.
4. `LOCAL NETWORK`는 Customer Network의 CIDR 값을 입력합니다. (192.168.0.0/16)
5. `REMOTE NETWORK`는 AWS Network의 CIDR 값을 입력합니다. (10.0.0.0/16)

```bash
conn Tunnel1
	authby=secret
	auto=start
	left=%defaultroute
	leftid=18.176.25.8
	right=3.37.114.133
	type=tunnel
	ikelifetime=8h
	keylife=1h
	phase2alg=aes_gcm
	ike=aes256-sha1
	keyingtries=%forever
	keyexchange=ike
	leftsubnet=192.168.0.0/16
	rightsubnet=10.0.0.0/16
	dpddelay=10
	dpdtimeout=30
	dpdaction=restart_by_peer
```

모두 변경하였다면 저장 후 나옵니다.

5) Create a new file at /etc/ipsec.d/aws.secrets if it doesn't already exist:

```bash
sudo vi /etc/ipsec.d/aws.secrets
```

파일 안에 엔트리를 집어넣습니다. **(본인의 configuration file 안의 내용을 집어넣습니다)**

```bash
18.176.25.8 3.37.114.133: PSK "Ns2Of1Wv24955RX7jjFyhzpsXfN4MsKw"
```

여기까지 마쳤다면 다음 명령어를 통해 ipsec 서비스를 시작합니다!

```bash
sudo systemctl start ipsec.service
```

다음 명령어를 통해 status를 확인할 수 있습니다.

```bash
sudo systemctl status ipsec.service
```

<img width="1384" alt="s2s8" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/a8f19e33-f09c-4062-b894-2d8925adb4bf">

터널이 생성되는 것을 확인할 수 있습니다. 다음과 같은 로그가 출력된다면 ipsec 터널이 정상적으로 연결되었음을 나타냅니다.

<img width="1202" alt="s2s9" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/df9c5e9c-2581-4c2b-85b8-31bc0c1f29d0">

AWS 매니지먼트 콘솔에서도 터널이 UP인 것을 확인할 수 있습니다.

마지막으로 Tokyo 리전의 Customer Network 상에 있는 EC2에서 AWS Network의 private ip로 접속이 가능한지 확인합니다.

```bash
ping <private-ip>
```

<img width="1386" alt="s2s10" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/936b9207-da54-4402-87b5-b8e2c5f407ca">

**트러블슈팅**

터널이 UP 상태로 바뀌지 않는 경우, `sudo systemctl status ipsec.service` 를 통해 로그를 확인합니다.

1. **IKE_AUTH response rejected Child SA with TS_UNACCEPTABLE, no connection named "Tunnel1”**
    - 이 경우 aws.conf 파일에 입력한 알고리즘 선택에 문제가 있을 확률이 높습니다. 올바른 알고리즘 조합을 사용하였는지 검토하고 `sudo systemctl restart ipsec.service` 명령어를 통해 다시 실행해보세요.
    - `journalctl -xe | grep pluto` 명령어를 통해 더 자세한 로그를 확인할 수 있습니다.

	<img width="1381" alt="s2s11" src="https://github.com/mushroom1324/aws-s2s-vpn-terraform/assets/76674422/d072e9e5-35ca-4777-979a-a14c2e1a0889">

    - 저의 경우에도 해당 명령어를 통해 ‘modp1024’를 지원하지 않는 것을 파악했습니다.

2. (리소스를 직접 구성하신 경우) 터널이 UP이지만 Ping이 실패하는 경우
    - AWS Network의 EC2에 할당되어 있는 Security Group이 Customer Network VPC의 CIDR에 대해 ICMP IPv4 All traffic를 허용하는지 확인합니다.
    - AWS Network의 Routing Table을 확인합니다. Customer Network VPC의 CIDR 범위는 Virtual Private Gateway를 향하도록 설정되어 있어야 합니다.
    - Customer Network의 Routing Table을 확인합니다. 0.0.0.0/0 범위에 대해 Internet Gateway를 향하도록 설정되어 있어야 합니다.
    - VPC Flow log를 활성화 하여 더욱 자세한 트러블 슈팅이 가능합니다.

AWS Site to Site VPN - Libreswan 연결 실습을 완료했습니다. 실습을 완료하셨다면 다음 명령어를 통해 리소스를 삭제합니다:

```bash
terraform destroy
```
