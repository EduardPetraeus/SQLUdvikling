--This script is related to Work Package: 3316 - Udarbejd script til migrering af tabeller fra Oracle 
CREATE OR REPLACE FUNCTION col_length (
    p_owner    VARCHAR2,
    p_table    VARCHAR2,
    p_column   VARCHAR2
) RETURN INTEGER AS
    v_length          NUMBER;
    v_buffer_factor   NUMBER := 1.2;
BEGIN
    EXECUTE IMMEDIATE 'SELECT MAX(LENGTH('
    || p_column
    || ')) FROM '
    || p_owner
    || '.'
    || p_table INTO
        v_length;

    v_length := v_length * v_buffer_factor;
    v_length :=
        CASE
            WHEN v_length = v_buffer_factor THEN 1
            WHEN v_length < 10 THEN 10
            WHEN v_length < 20 THEN 20
            WHEN v_length < 50 THEN 50
            WHEN v_length < 100 THEN 100
            WHEN v_length < 250 THEN 250
            WHEN v_length < 500 THEN 500
            WHEN v_length < 1000 THEN 1000
            WHEN v_length < 2000 THEN 2000
            ELSE 4000
        END;

    RETURN v_length;
END col_length;
/

CREATE OR REPLACE FUNCTION get_datatype (
    p_owner            VARCHAR2,
    p_table            VARCHAR2,
    p_column           VARCHAR2,
    p_column_id        NUMBER,
    p_data_type        VARCHAR2,
    p_data_precision   NUMBER,
    p_data_scale       NUMBER,
    p_data_length      NUMBER,
    p_nullable         VARCHAR2
) RETURN VARCHAR2 AS

    v_text              LONG;
    v_datatype          LONG;
    v_output            VARCHAR2(4000);
    v_scale             NUMBER;
    v_precision         NUMBER;
    v_primary_key       NUMBER; --0=no, 1=yes
BEGIN
    

    SELECT count(*)
    INTO v_primary_key
    FROM all_constraints cons, all_cons_columns cols
    WHERE cols.table_name = p_table 
    AND cons.constraint_type = 'P'
    AND cons.constraint_name = cols.constraint_name
    AND cons.owner = cols.owner
    AND cons.owner = p_owner
    AND cols.column_name = p_column;

    IF
        p_data_type = 'NUMBER'
    THEN
        EXECUTE IMMEDIATE 'SELECT MAX(LENGTH(TO_CHAR(trunc(ABS('
        || p_column
        || '))))),
        MAX(LENGTH(TO_CHAR(MOD(ABS('
        || p_column
        || '), 1))) -1) FROM '
        || p_owner
        || '.'
        || p_table INTO
            v_scale,v_precision;

        IF
            v_precision = 0
        THEN
            v_datatype :=
                CASE
                    WHEN v_scale < 10 THEN 'int'
                    WHEN v_scale <= 19 THEN 'bigint'
                    ELSE '**** ERROR'
                END;

        ELSE
            v_datatype := 'float';
        END IF;

        --dzi_fælles.custom_logging_api.insert_logging('p_table: '
        --|| p_table
        --|| ' p_column: '
        --|| p_column
        --|| ' v_scale: '
        --|| v_scale
        --|| ' v_precision: '
        --|| v_precision);

        --dzi_fælles.custom_logging_api.insert_logging('v_datatype: '
        --|| v_datatype);
        SELECT
            DECODE(p_column_id,1,'   ','  ,')
            || rtrim(p_column)
            || ' '
            || v_datatype
            || rtrim(DECODE(p_nullable,'N',' NOT NULL',NULL) )
            || DECODE(v_primary_key,1,' PRIMARY KEY',NULL)
        INTO
            v_text
        FROM
            dual;
    ELSIF p_data_type = 'DATE' THEN
        
        --Check if there are any dates with time part in the column. We use v_scale variable, even though its a count just to not declare a new variable.
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table || ' WHERE '|| p_column || ' <>  TRUNC( ' || p_column || ')' INTO v_scale;
        IF v_scale > 0 THEN
            v_datatype := 'datetime';
        ELSE
            v_datatype := 'date';
        END IF;

        SELECT
            DECODE(p_column_id,1,'   ','  ,')
            || rtrim(p_column)
            || ' '
            || v_datatype
            || rtrim(DECODE(p_nullable,'N',' NOT NULL',NULL) )
            || DECODE(v_primary_key,1,' PRIMARY KEY',NULL)
        INTO
            v_text
        FROM
            dual;
    ELSE
        SELECT
            DECODE(p_column_id,1,'   ','  ,')
            || rtrim(p_column)
            || ' '
            || DECODE(rtrim(p_data_type),'VARCHAR2','nvarchar','NUMBER','int',lower(p_data_type) )
            || rtrim(DECODE(p_data_type,'DATE',NULL,'LONG',NULL,'NUMBER',DECODE(TO_CHAR(p_data_precision),NULL,NULL,'('),'(') )
            || rtrim(DECODE(p_data_type,'DATE',NULL,'CHAR',p_data_length,'VARCHAR2',col_length(p_owner,p_table,p_column),'NUMBER',DECODE(TO_CHAR(p_data_precision),NULL,NULL,TO_CHAR(p_data_precision)
            || ','
            || TO_CHAR(p_data_scale) ),'LONG',NULL,'******ERROR') )
            || rtrim(DECODE(p_data_type,'DATE',NULL,'LONG',NULL,'NUMBER',DECODE(TO_CHAR(p_data_precision),NULL,NULL,')'),')') )
            || rtrim(DECODE(p_nullable,'N',' NOT NULL',NULL) )
            || rtrim(DECODE(v_primary_key,1,' PRIMARY KEY',NULL) )
        INTO
            v_text
        FROM
            dual;

    END IF;

    v_output := substr(v_text,1,4000);
    RETURN v_output;
END get_datatype;
/

SELECT
    table_name y,
    0 x,
    'CREATE TABLE DMSA.'
    || rtrim(table_name)
    || '(' z
FROM
    dba_tables
WHERE
    owner = 'AT6_DM'
    --AND   table_name = 'UDENLANDSK_VIRKSOMHED_DIM'
UNION
SELECT
    tc.table_name y,
    column_id x,
    get_datatype(tc.owner,tc.table_name,tc.column_name,column_id,data_type,data_precision,data_scale,data_length,nullable)
FROM
    dba_tab_columns tc,
    dba_objects o
WHERE
    o.owner = tc.owner
    AND   o.object_name = tc.table_name
    AND   o.object_type = 'TABLE'
    AND   o.owner = 'AT6_DM'
    --AND   tc.table_name = 'UDENLANDSK_VIRKSOMHED_DIM'
UNION
SELECT
    table_name y,
    999998 x,
    ')'
FROM
    dba_tables
WHERE
    owner = 'AT6_DM'
    --AND   table_name = 'UDENLANDSK_VIRKSOMHED_DIM'
UNION
SELECT
    table_name y,
    999999 x,
    'GO'
FROM
    dba_tables
WHERE
    owner = 'AT6_DM'
    --AND   table_name = 'UDENLANDSK_VIRKSOMHED_DIM'
ORDER BY
    1,
    2;

DROP FUNCTION col_length;
DROP FUNCTION get_datatype;