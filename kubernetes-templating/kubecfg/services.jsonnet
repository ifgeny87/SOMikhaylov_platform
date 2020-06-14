local kube = import "https://raw.githubusercontent.com/bitnami-labs/kube-libsonnet/52ba963ca44f7a4960aeae9ee0fbee44726e481f/kube.libsonnet";

local common(name) = {

  service: kube.Service(name) {
    metadata+: {
      labels: {},
    },
    target_pod:: $.deployment.spec.template,
  },

  deployment: kube.Deployment(name) {
    metadata+: {
      labels: {
        app: name,
      },
    },
    spec+: {
      template+: {
        spec+: {
          containers_: {
            common: kube.Container("common") {
              name: "server",
              env: [{name: "PORT", value: "50051"}],
              ports: [{containerPort: 50051}],
              resources: {
                requests: {
                  cpu: "100m",
                  memory: "64Mi",
                },
                limits: {
                  cpu: "200m",
                  memory: "128Mi",
                },
              },
              readinessProbe: {
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:50051",
                      ],
                  },
              },
              livenessProbe: {
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:50051",
                      ],
                  },
              },
            },
          },
        },
      },
    },
  },
};

{
  catalogue: common("paymentservice") {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              common+: {
                image: "gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3",
              },
            },
          },
        },
      },
    },
  },

  payment: common("shippingservice") {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              common+: {
                image: "gcr.io/google-samples/microservices-demo/shippingservice:v0.1.3",
                readinessProbe+: {
                    periodSeconds: 5,
                },
              },
            },
          },
        },
      },
    },
  },
}

