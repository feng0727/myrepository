package com.broada.control;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/*
 * @Description
 * @Author  xuebing feng
 * @Date   $date$ $time$
 */
@RestController
public class SayHello {

    @RequestMapping("/say")
    public  String sqy(){
        return "Hello";
    }

}
