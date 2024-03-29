/*
ORACLE_create_DDL_reverse_script_of_table
ORACLE Table 의 DDL 리버스 스크립트 생성

DA# 에 사용할 reverse script 를 생성하기 위한 목적으로 만들었습니다.
DA# 에서 script reverse 진행 시 인식하지 못하는 내용들이 있어,
아래와 같이 reverse script 생성 후 변환작업이 필요합니다.


https://www.morganslibrary.org/reference/pkgs/dbms_metadata.html

*/

SET pagesize 0
SET long 90000
SET linesize 2000
SET feedback OFF
SET echo OFF
SET TRIM ON
SET trimspool ON



-- 파일생성하지 않고 출력창에서 볼 경우에는 space 가 생김.
SPOOL [생성할 파일 명]_20220101.SQL


---- omit the TABLESPACE clause
--EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', FALSE);

-- omit the storage clause
EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', FALSE);

-- omit the segment attributes clause
EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', FALSE);

-- insert ';'
EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',TRUE) ;




--EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'STORAGE',FALSE) ;
--
--EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'TABLESPACE',FALSE) ;
--
EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SEGMENT_ATTRIBUTES',FALSE) ;


--EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'PRETTY',TRUE) ;
--
--EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'BODY',FALSE) ;

--EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'CONSTRAINTS',FALSE) 

EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform,'PARTITIONING',FALSE) ;




WITH TBL_LIST AS
(
-- 주제영역 : 주제영역1
-- 테이블을 직접 지정하여 UNION ALL 한 DA# 에서 주제영역별로 사용할 script 분리생성하기 위함
SELECT '[OWNER]' OWNER, '[TABLE_NAME]' TBL FROM dual aa
UNION ALL SELECT '[OWNER]' OWNER, '[TABLE_NAME]' TBL FROM dual aa
UNION ALL SELECT '[OWNER]' OWNER, '[TABLE_NAME]' TBL FROM dual aa
UNION ALL SELECT '[OWNER]' OWNER, '[TABLE_NAME]' TBL FROM dual aa
UNION ALL SELECT '[OWNER]' OWNER, '[TABLE_NAME]' TBL FROM dual aa
UNION ALL SELECT '[OWNER]' OWNER, '[TABLE_NAME]' TBL FROM dual aa
--
)
, TBL_LIST_CAP AS
(
  SELECT
          tl.*,
          ( SELECT COUNT(*) FROM ALL_TAB_COMMENTS atc WHERE atc.OWNER = tl.OWNER AND atc.TABLE_NAME = tl.TBL AND ATC.COMMENTS IS NOT NULL )
            + ( SELECT COUNT(*) FROM ALL_COL_COMMENTS cc WHERE cc.OWNER = tl.OWNER AND cc.TABLE_NAME = tl.TBL AND CC.COMMENTS IS NOT NULL ) CMT_CNT
  FROM TBL_LIST tl
)
, OBJ_LIST AS
(
SELECT
        aa.OWNER, aa.TBL TABLE_NAME, 1 OBJECT_SEQ,
        AO.OBJECT_TYPE, AO.OBJECT_NAME,
        REPLACE( DBMS_METADATA.GET_DDL(AO.OBJECT_TYPE, AO.OBJECT_NAME, aa.OWNER), '"', '') SCRIPT
FROM TBL_LIST_CAP aa
  INNER JOIN ALL_OBJECTS ao
    ON AO.OWNER = aa.OWNER AND AO.OBJECT_NAME = aa.TBL
WHERE AO.OBJECT_TYPE IN ('TABLE')
UNION ALL
SELECT
        aa.OWNER, aa.TBL TABLE_NAME, 2 OBJECT_SEQ,
        AO.OBJECT_TYPE, AO.OBJECT_NAME,
        REPLACE( DBMS_METADATA.GET_DEPENDENT_DDL('COMMENT', AO.OBJECT_NAME, aa.OWNER), '"', '') SCRIPT
FROM TBL_LIST_CAP aa
  INNER JOIN ALL_OBJECTS ao
    ON AO.OWNER = aa.OWNER AND AO.OBJECT_NAME = aa.TBL
WHERE AO.OBJECT_TYPE IN ('TABLE')
  AND aa.CMT_CNT > 0
UNION ALL
SELECT
        aa.OWNER, aa.TBL TABLE_NAME, 3 OBJECT_SEQ,
        'INDEX' OBJECT_TYPE, AI.INDEX_NAME OBJECT_NAME,
        REPLACE( DBMS_METADATA.GET_DDL('INDEX', AI.INDEX_NAME, aa.OWNER), '"', '') SCRIPT
FROM TBL_LIST_CAP aa
  INNER JOIN ALL_INDEXES ai
    ON AI.OWNER = aa.OWNER AND AI.TABLE_NAME = aa.TBL
UNION ALL
SELECT
        aa.OWNER, aa.TBL TABLE_NAME, 4 OBJECT_SEQ,
        'CONSTRAINT' OBJECT_TYPE, AC.CONSTRAINT_NAME OBJECT_NAME,
        REPLACE( DBMS_METADATA.GET_DDL('CONSTRAINT', AC.CONSTRAINT_NAME, aa.OWNER), '"', '') SCRIPT
FROM TBL_LIST_CAP aa
  INNER JOIN ALL_CONSTRAINTS ac
    ON AC.OWNER = aa.OWNER AND AC.TABLE_NAME = aa.TBL
WHERE AC.CONSTRAINT_TYPE IN ('U', 'P')
--
)
SELECT
--        aa.*
        aa.SCRIPT
FROM OBJ_LIST aa
WHERE aa.OBJECT_NAME IS NOT NULL
ORDER BY aa.OWNER ASC, aa.TABLE_NAME ASC, aa.OBJECT_SEQ ASC
;





SPOOL OFF




-- reverse to default setting
EXEC dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'DEFAULT');
