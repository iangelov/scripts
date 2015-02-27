package main

import (
	"fmt"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
	"log"
	"os"
	"regexp"
)

var allRegions = map[string]aws.Region{
	"eu-west-1":      aws.EUWest,
	"eu-central-1":   aws.EUCentral,
	"us-east-1":      aws.USEast,
	"us-west-1":      aws.USWest,
	"us-west-2":      aws.USWest2,
	"ap-southeast-1": aws.APSoutheast,
	"ap-southeast-2": aws.APSoutheast2,
	"ap-northeast-1": aws.APNortheast,
	"sa-east-1":      aws.SAEast,
	"cn-north-1":     aws.CNNorth,
	"us-gov-west-1":  aws.USGovWest,
}

func main() {
	auth, err := aws.GetAuth("", "")
	if err != nil {
		log.Fatal(err)
	}

	options := &ec2.DescribeInstanceStatus{}
	filter := ec2.NewFilter()
	filter.Add("event.code", "*")
	filter.Add("instance-state-name", "running")

	client := ec2.New(auth, getRegion(os.Getenv("EC2_REGION")))
	resp, err := client.DescribeInstanceStatus(options, filter)

	if err != nil {
		log.Fatal(err)
	}

	instanceId := make([]string, 1)

	for _, i := range resp.InstanceStatus {
		for _, e := range i.Events {
			m, err := regexp.Match("Completed", []byte(e.Description))
			if err != nil {
				fmt.Println(err)
			}
			if !m {
				fmt.Printf("%v:\n", os.Getenv("EC2_PROFILE"))
				fmt.Printf("Instance id: %v\nEvent code: %v\nEvent description: %v\nBetween: %v and %v\n",
					i.InstanceId, e.Code, e.Description, e.NotBefore, e.NotAfter)
				instanceId[0] = i.InstanceId
				fmt.Println("Name:", getInstanceName(client, instanceId))
			}
		}
	}

}

func getInstanceName(c *ec2.EC2, i []string) string {
	resp, err := c.Instances(i, nil)

	if err != nil {
		log.Fatal(err)
	}

	instanceName := ""

	for _, r := range resp.Reservations {
		for _, ri := range r.Instances {
			for _, t := range ri.Tags {
				if t.Key == "Name" {
					instanceName = t.Value
				}
			}
		}
	}

	return instanceName
}

func getRegion(r string) aws.Region {
	return allRegions[r]
}
