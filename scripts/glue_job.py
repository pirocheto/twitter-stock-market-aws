import sys

import gs_array_to_cols
import gs_explode
import gs_flatten
import gs_split
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame, DynamicFrameCollection
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext


# Script generated for node Custom Transform
def MyTransform(glueContext, dfc) -> DynamicFrameCollection:
    # Import necessary libraries
    from pyspark.sql.functions import to_timestamp

    # Set legacy time parser policy for compatibility
    spark.conf.set("spark.sql.legacy.timeParserPolicy", "LEGACY")

    # Select the first DynamicFrame from the DynamicFrameCollection
    dynamic_frame = dfc.select(list(dfc.keys())[0])

    # Convert DynamicFrame to DataFrame
    data_frame = dynamic_frame.toDF()

    # Define the input date format
    input_format = "E, dd MMM yyyy HH:mm:ss z"

    # Apply timestamp conversion to the 'date' column using the specified format
    formatted_df = data_frame.withColumn(
        "timestamp", to_timestamp("date", input_format)
    )

    # Convert the modified DataFrame back to a DynamicFrame
    formatted_dynamic_frame = DynamicFrame.fromDF(
        formatted_df, glueContext, "formatted_df"
    )

    # Create a DynamicFrameCollection containing the formatted DynamicFrame
    formatted_dfc = DynamicFrameCollection(
        {"result": formatted_dynamic_frame}, glueContext
    )

    # Return the DynamicFrameCollection
    return formatted_dfc


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node Amazon S3
AmazonS3_node1708205076803 = glueContext.create_dynamic_frame.from_options(
    format_options={"multiline": False},
    connection_type="s3",
    format="json",
    connection_options={
        "paths": ["s3://twitter-stock-market-data-storage/stock_market/landing/"],
        "recurse": True,
    },
    transformation_ctx="AmazonS3_node1708205076803",
)

# Script generated for node Flatten
Flatten_node1708206854805 = AmazonS3_node1708205076803.gs_flatten()

# Script generated for node Change Schema
ChangeSchema_node1708207481982 = ApplyMapping.apply(
    frame=Flatten_node1708206854805,
    mappings=[
        ("`Headers.date`", "array", "date", "array"),
        ("`ResponseBody.c`", "double", "current_price", "double"),
        ("`ResponseBody.d`", "double", "change", "double"),
        ("`ResponseBody.dp`", "double", "percent_change", "double"),
        ("`ResponseBody.h`", "double", "high_price_of_the_day", "double"),
        ("`ResponseBody.l`", "double", "low_price_of_the_day", "double"),
        ("`ResponseBody.o`", "double", "open_price_of_the_day", "double"),
        ("`ResponseBody.pc`", "double", "previous_close_price", "double"),
    ],
    transformation_ctx="ChangeSchema_node1708207481982",
)

# Script generated for node Explode Array Or Map Into Rows
ExplodeArrayOrMapIntoRows_node1708218228389 = ChangeSchema_node1708207481982.gs_explode(
    colName="date", newCol="date"
)

# Script generated for node Custom Transform
CustomTransform_node1708218517485 = MyTransform(
    glueContext,
    DynamicFrameCollection(
        {
            "ExplodeArrayOrMapIntoRows_node1708218228389": ExplodeArrayOrMapIntoRows_node1708218228389
        },
        glueContext,
    ),
)

# Script generated for node Select From Collection
SelectFromCollection_node1708223874029 = SelectFromCollection.apply(
    dfc=CustomTransform_node1708218517485,
    key=list(CustomTransform_node1708218517485.keys())[0],
    transformation_ctx="SelectFromCollection_node1708223874029",
)

# Script generated for node Split String
SplitString_node1708223922563 = SelectFromCollection_node1708223874029.gs_split(
    colName="timestamp", pattern="[- ]", newColName="timestamp_array"
)

# Script generated for node Array To Columns
ArrayToColumns_node1708223984603 = SplitString_node1708223922563.gs_array_to_cols(
    colName="timestamp_array", colList="year,month,day"
)

# Script generated for node Drop Fields
DropFields_node1708262398653 = DropFields.apply(
    frame=ArrayToColumns_node1708223984603,
    paths=["timestamp_array"],
    transformation_ctx="DropFields_node1708262398653",
)

# Script generated for node AWS Glue Data Catalog
AWSGlueDataCatalog_node1708259851997 = glueContext.write_dynamic_frame.from_catalog(
    frame=DropFields_node1708262398653,
    database="twitter_stock_market",
    table_name="stock_market_curated",
    additional_options={"partitionKeys": ["year", "month", "day"]},
    transformation_ctx="AWSGlueDataCatalog_node1708259851997",
)

job.commit()
