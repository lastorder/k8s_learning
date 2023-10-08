import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as eks from 'aws-cdk-lib/aws-eks';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';

export class AwsEksStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Define a VPC with two public subnets in different AZs
    const vpc = new ec2.Vpc(this, 'cdk-eks-vpc', {
      maxAzs: 2, // Specify the number of AZs
      natGateways: 0, // Reduce the NAT gateway cost
      vpcName: 'cdk-eks-vpc',
      subnetConfiguration: [
        {
          name: 'cdk-eks-public',
          subnetType: ec2.SubnetType.PUBLIC,
        }
      ],
    });

    const cluster = new eks.Cluster(this, 'cdk-eks', {
      clusterName: "cdk-eks",
      version: eks.KubernetesVersion.V1_27,
      albController: {
        version: eks.AlbControllerVersion.V2_5_1,
      },
      defaultCapacity: 0,
      vpc: vpc,
      vpcSubnets: [{ subnetType: ec2.SubnetType.PUBLIC }]
    });

    cluster.addNodegroupCapacity('cdk-eks-node-group', {
      instanceTypes: [new ec2.InstanceType('t2.small')],
      minSize: 1,
      maxSize: 2,
      diskSize: 20,
      amiType: eks.NodegroupAmiType.AL2_X86_64,
    });

    this.addClusterAdmin(cluster, "k8s_adminer");
    this.addClusterAdmin(cluster, "dong.yu");
  }

  private addClusterAdmin(cluster: eks.Cluster, name: string) {

    const userByName = iam.User.fromUserName(this,name,name,);

    cluster.awsAuth.addUserMapping(userByName, {
      groups: ['system:masters']
    });
  }
}
