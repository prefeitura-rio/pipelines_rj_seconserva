# -*- coding: utf-8 -*-
"""
Database dumping flows for EGPWeb project.
"""

from copy import deepcopy

from prefect.run_configs import KubernetesRun
from prefect.storage import GCS
from prefeitura_rio.pipelines_templates.dump_db.flows import flow as dump_sql_flow
from prefeitura_rio.pipelines_utils.prefect import set_default_parameters
from prefeitura_rio.pipelines_utils.state_handlers import (
    handler_initialize_sentry,
    handler_inject_bd_credentials,
)

from pipelines.constants import constants
from pipelines.siscor.dump_db.schedules import siscor_update_schedule

siscor_flow = deepcopy(dump_sql_flow)
siscor_flow.name = "SMI: SISCOR - Ingerir tabelas de banco SQL"
siscor_flow.state_handlers = [handler_inject_bd_credentials, handler_initialize_sentry]
siscor_flow.storage = GCS(constants.GCS_FLOWS_BUCKET.value)
siscor_flow.run_config = KubernetesRun(
    image=constants.DOCKER_IMAGE.value,
    labels=[
        constants.RJ_SECONSERVA_AGENT_LABEL.value,
    ],
)

siscor_default_parameters = {
    "db_database": "siscor_seconserva",
    "db_host": "10.70.11.61",
    "db_port": "1433",
    "db_type": "sql_server",
    "infisical_secret_path": "/db-siscor", #lembrar
    "materialization_mode": "prod",
    "materialize_to_datario": False,
    "dataset_id": "infraestrutura_siscor_obras",
}

siscor_flow = set_default_parameters(siscor_flow, default_parameters=siscor_default_parameters)

siscor_flow.schedule = siscor_update_schedule

# comment to trigger actions