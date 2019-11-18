package com.broada.service;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.broada.entity.SQLVisualization;
import com.broada.utils.ExcelUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.PropertySource;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ResultSetExtractor;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.*;

@Service
@PropertySource("classpath:application.properties")
public class QueryBusinessService {

    @Value("${OracleUrl}")
    private String OracleUrl;

    @Value("${MySQLUrl}")
    private String MySQLUrl;

    @Autowired
    private JdbcTemplate jdbcTemplate;
    private static  final Logger LOG= LoggerFactory.getLogger(QueryBusinessService.class);

    //查询业务数据库信息
    public JSON findAllBusinessInfo(Integer pageNum, Integer pageSize, String username, String dbname, String businessname) {

         List<String> params = new ArrayList<>();//存放参数
         List<String> conditions = new ArrayList<>();
        String sql ="SELECT id,username,password,businessname,dbname,dbtype,dbport FROM businsystem where 1=1";
        String  countsql="SELECT count(id) FROM businsystem  where 1=1";
         if (hasLength(username)){
            sql = sql + " and username like '%" + username + "%' ";
            countsql = countsql + " and username like '%" + username + "%' ";

        }
        if(hasLength(dbname)) {
            sql=sql+ " and dbname like '%" + dbname + "%' ";
            countsql=countsql+ " and dbname like '%" + dbname + "%' ";

        }
        if(hasLength(businessname)) {
            sql=sql+ " and businessname like '%" + businessname + "%' ";
            countsql=countsql+ " and businessname like '%" + businessname + "%' ";

        }

        if (pageNum!=null &&pageSize!=null){
            int intPageNum = pageNum.intValue() - 1;
            sql+="  LIMIT "+intPageNum+","+pageSize+"";
        }
 
        List<SQLVisualization> equipmentList = jdbcTemplate.query(sql.toString(),new Object[]{}, new BusinInfoRowMapper());
        JSONObject resobj=new JSONObject();
        if (equipmentList!=null){
            int total = jdbcTemplate.queryForObject(countsql, Integer.class);
            JSONArray array=new JSONArray();
            for (int i = 0; i < equipmentList.size(); i++) {
                JSONObject obj = (JSONObject) JSONObject.toJSON(equipmentList.get(i));
                array.add(obj);
            }
            resobj.put("totalRecords",total);
            resobj.put("dataList",array);
        }

        return resobj;
    }
    /**
     *
     * @param sqlData
     * 新增系统信息
     */
    public void insertBusiness(SQLVisualization sqlData) {
        String sql = "insert into businsystem(id,username,password,businessname,dbtype,dbname,dbport) values(null,?,?,?,?,?,?)";
        int resStatus = jdbcTemplate.update(sql,sqlData.getUsername().toString(),sqlData.getPassword().toString(),sqlData.getBusinessname().toString(),sqlData.getDbtype().toString(),sqlData.getDbname().toString(),sqlData.getDbport().toString());

    }

    /**
     *
     * @param sqlData
     * 修改系统信息
     */
    public void updateBusiness(SQLVisualization sqlData) {
        String sql = "update businsystem set username=?,password=?,businessname=?,dbtype=?,dbname=?,dbport=? where id=?";
        int resStatus = jdbcTemplate.update(sql,sqlData.getUsername().toString(),sqlData.getPassword().toString(),sqlData.getBusinessname().toString(),sqlData.getDbtype().toString(),sqlData.getDbname().toString(),sqlData.getDbport().toString(),sqlData.getId().toString());
        System.out.println(resStatus);
    }

    /**
     * @Deeccript 修改系统信息
     * @param ids
     * @author
     */
    public void deleteBusiness(String ids) {
        if (ids!=null){
           //ids String[] split = ids.split(",");
            String delSql="delete from businsystem where id in(?)";
            jdbcTemplate.update(delSql, ids);
        }

    }


    /**
    * @Description  执行sql查询
    * @Author  xuebing feng
    * @Date   2019/11/6 15:50:46
    * @Param
    * @Return
    * @Exception
    */
    public JSONObject executeSQL(String queryId,String sqlString) {
        //先确定数据库类型和数据库名称
        String sql = "SELECT id,username,password,businessname,dbname,dbtype,dbport FROM businsystem where id=?";
        List<SQLVisualization> query = jdbcTemplate.query(sql, new Object[]{queryId}, new BusinInfoRowMapper());
        SQLVisualization sqlVisualization = null;
        JSONObject jsonObject = new JSONObject();
        if (!query.isEmpty()) {
            sqlVisualization = query.get(0);
        }
        if ("ORACLE".equals(sqlVisualization.getDbtype())) {
            try {
                JSONObject orclObj = new JSONObject();
                DriverManagerDataSource dmds = new DriverManagerDataSource();
                dmds.setDriverClassName("oracle.jdbc.driver.OracleDriver");
                dmds.setUrl(OracleUrl);
                //todo
                 dmds.setUsername(sqlVisualization.getUsername());
                dmds.setPassword(sqlVisualization.getPassword());
                JdbcTemplate orcljt = new JdbcTemplate(dmds);
                //查询列信息 的sql
                // List list_map = getSqlResult(sqlString, orcljt);
                try {
                    JSONObject result = getSqlResult(sqlString, orcljt);
                    return result;
                }
                catch (Exception e){
                    e.printStackTrace();
                    jsonObject.put("error","error");
                    jsonObject.put("message",e.getMessage());
                }

            }catch (Exception e){
                 e.printStackTrace();
            }
        }
         if ("MySQL".equals(sqlVisualization.getDbtype())) {
              try {
                  DriverManagerDataSource dmds = new DriverManagerDataSource();
                  dmds.setDriverClassName("com.mysql.jdbc.Driver");
                  dmds.setUrl(MySQLUrl);
                  //todo
                  dmds.setUsername(sqlVisualization.getUsername());
                  dmds.setPassword(sqlVisualization.getPassword());

                  JdbcTemplate jt = new JdbcTemplate(dmds);
                  //执行mysql的查询语句
                  try {
                      JSONObject result = getSqlResult(sqlString, jt);
                      return result;
                  }
                  catch (Exception e){
                      e.printStackTrace();
                      jsonObject.put("error","error");
                      jsonObject.put("message",e.getMessage());


                  }

              }catch (Exception e){
                  e.printStackTrace();
                  jsonObject.put("error","连接失败");
              }

          }
            return jsonObject;

    }

    
    
    /**
    * @Description
    * @Author  xuebing feng
    * @Date   2019/11/6 15:48:27
    * @Param  
    * @Return
    * @Exception   
    */
    public void exceptExcel(String queryId, String sqlQuery,HttpServletResponse response) {

        //先确定数据库类型和数据库名称
        String lksqlQuery = sqlQuery.replace("\n", "");
        JSONObject jsonObject = executeSQL(queryId, lksqlQuery);
        JSONArray dataArray=new JSONArray();
        List dataList=new ArrayList();
        if (jsonObject.containsKey("dataList")) {
              dataList  = (List) jsonObject.get("dataList");
        }
        Map map = (Map) dataList.get(0);
        Set<String> set = map.keySet();
        Map  headMap=new HashMap();
        for(String key:set) {
            headMap.put(key, key);
        }
        for (int i = 0; i <dataList.size(); i++) {
                JSONObject obj = (JSONObject) JSONObject.toJSON(dataList.get(i));
                dataArray.add(obj);
            }

            System.out.println(dataArray);
            ExcelUtil.downloadExcelFile("业务系统",headMap,dataArray,response);
            System.out.println("success");
        }

    /**
    * @Description  实体映射
    * @Author  xuebing feng
    * @Date   2019/11/6 15:51:14
    * @Param
    * @Return
    * @Exception
    */
    public  class BusinInfoRowMapper implements RowMapper<SQLVisualization> {
        @Override
        public SQLVisualization mapRow(ResultSet rs, int num) throws SQLException {
            //从结果集里把数据得到
            String id = rs.getString("id");
            String username = rs.getString("username");
            String password = rs.getString("password");
            String businessname = rs.getString("businessname");
            String dbtype = rs.getString("dbtype");
            String dbname = rs.getString("dbname");
            String dbport = rs.getString("dbport");
            //把数据封装到对象里
            SQLVisualization sqlVisualization = new SQLVisualization();
            sqlVisualization.setId(id);
            sqlVisualization.setBusinessname(businessname);
            sqlVisualization.setUsername(username);
            sqlVisualization.setDbname(dbname);
            sqlVisualization.setDbport(dbport);
            sqlVisualization.setDbtype(dbtype);
            sqlVisualization.setPassword(password);

            return sqlVisualization;

        }
    }


    /**
    * @Description  判空
    * @Author  xuebing feng
    * @Date   2019/11/6 15:51:38
    * @Param
    * @Return
    * @Exception
    */
    public boolean hasLength(String str){
        return str!=null && !"".equals(str.trim());
    }


    /**
    * @Description  执行sql
    * @Author  xuebing feng
    * @Date   2019/11/7 13:27:50
    * @Param
    * @Return
    * @Exception
    */
    public JSONObject getSqlResult(String sqlString,JdbcTemplate jtl){
       JSONObject jsonObject=new JSONObject();
        List result = jtl.query(sqlString, new ResultSetExtractor<List>() {
            @Override
            public List extractData(ResultSet rs) throws SQLException, DataAccessException {
                List list = new ArrayList();
                ResultSetMetaData md = rs.getMetaData();//获取键名
                int columnCount = md.getColumnCount();//获取行的数量
                while (rs.next()) {
                    Map rowData = new HashMap();//声明Map
                    for (int i = 1; i <= columnCount; i++) {
                        rowData.put(md.getColumnName(i), rs.getObject(i));//获取键名及值
                    }
                    list.add(rowData);
                }
                if (list.size()==0){
                    for(int i = 1; i <= columnCount; i++){
                        String columnLabel = md.getColumnLabel(i);
                        list.add(columnLabel);
                        jsonObject.put("columInfo", list);
                    }
                }else{
                    Map map = (Map) list.get(0);
                    Set<String> set = map.keySet();
                    List columInfoList = new ArrayList();
                    for (String key : set) {
                        columInfoList.add(key);
                    }
                    // System.out.println("columInfoList: "+columInfoList);
                    jsonObject.put("columInfo", columInfoList);
                    jsonObject.put("dataList", list);
                }

                LOG.info(list.toString());
                return list;
                }

        });

        return jsonObject;
    }

}

