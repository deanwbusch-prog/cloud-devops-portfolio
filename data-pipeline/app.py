#!/usr/bin/env python3
import aws_cdk as cdk

from data_pipeline_stack import DataPipelineStack

app = cdk.App()

project_name = app.node.try_get_context("project_name") or "data-pipeline"
region = app.node.try_get_context("region") or "us-east-2"
env = cdk.Environment(account=None, region=region)

DataPipelineStack(
    app,
    "DataPipelineStack",
    project_name=project_name,
    env=env,
)

app.synth()
