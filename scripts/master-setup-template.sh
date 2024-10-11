#!/bin/bash
chmod +x /home/ubuntu/master-setup.sh
/home/ubuntu/master-setup.sh
echo 'master ${self.private_ip}' >> /home/ubuntu/ips.txt
%{ for i in range(var.node_count) ~}
echo 'worker-${i} ${aws_instance.wnode[i].private_ip}' >> /home/ubuntu/ips.txt
%{ endfor ~}
