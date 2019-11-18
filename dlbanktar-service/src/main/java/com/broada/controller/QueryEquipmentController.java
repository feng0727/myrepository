package com.broada.controller;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.broada.entity.SQLVisualization;
import com.broada.service.QueryBusinessService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

@RestController
@RequestMapping("/server")
public class QueryEquipmentController {


     @Autowired
    private QueryBusinessService queryBusinessService;
    /**
    * @Description 根据条件查询 和查询全部
    * @Author  xuebing feng
    * @Date   2019/11/5 16:07:53
    * @Param
    * @Return
    * @Exception
    */
     @RequestMapping("/findAllBusinessInfo")
    public JSON findAllBusinessInfo(@RequestParam(value ="pageNum",required =false) Integer pageNum, @RequestParam(value = "pageSize",required = false) Integer pageSize, @RequestParam(value = "businessname",required = false) String businessname, @RequestParam(value = "dbname",required = false) String dbname, @RequestParam(value = "username",required = false) String username){
         return queryBusinessService.findAllBusinessInfo(pageNum,pageSize,username,dbname,businessname);
    }


     /**
    * @Description 新增业务系统
    * @Author  xuebing feng
    * @Date   2019/11/5 16:07:40
    * @Param
    * @Return
    * @Exception
    */
    @PostMapping("/updateBusiness")
    public void insertOrUpdateBusiness(@RequestBody SQLVisualization sqlData){
        if (sqlData.getId()==null||"".equals(sqlData)){
            queryBusinessService.insertBusiness(sqlData);
           }
        else {
            queryBusinessService.updateBusiness(sqlData);
        }
    }

   
    /**
   * @Description
   * @Author  xuebing feng
   * @Date   2019/11/5 15:44:05
   * @Param  
   * @Return      
   * @Exception   
   */
    @RequestMapping("/deleteBusiness")
    public void deleteBusiness(String ids){
        queryBusinessService.deleteBusiness(ids);
    }


    /**
    * @Description  通过id查询
    * @Author  xuebing feng
    * @Date   2019/11/5 16:09:03
    * @Param
    * @Return
    * @Exception
    */

    @RequestMapping("/executeSQL")
    public JSONObject  executeSQL(@RequestBody JSONObject jsonObject){
        String queryId = jsonObject.get("queryId").toString();
        String sqlQuery = jsonObject.get("sqlQuery").toString();
        return queryBusinessService.executeSQL(queryId, sqlQuery);
    }

    @RequestMapping("/exceptExcel")
    public void  exceptExcel(@RequestBody JSONObject jsonObject,HttpServletResponse response){
        String queryId = jsonObject.get("queryId").toString();
        String sqlQuery = jsonObject.get("sqlQuery").toString();
        queryBusinessService.exceptExcel(queryId, sqlQuery,response);
    }




}
