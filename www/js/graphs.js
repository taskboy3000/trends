$(document).ready(function()
{
   jQuery.ajaxSetup({
                        dataType: "json",
                        type: "GET",
                        cache: true,
                    });

   $.getScript("http://www.google.com/jsapi", function()  
   {

        google.load("visualization", "1.0", { packages : [ 'corechart' ],
                                              callback : function() { 
            $.ajax({
               url : "/api/data/changes/tech_this_week.json",
               success: function(d)
                        {
                           paint_top_techs(d, document.getElementById("all-projects-last-week"));
                        }
            });

            $.ajax({
               url : "/api/data/changes/tech_this_week.json",
               success: function(d)
                        {
                           paint_top_five_techs_chart(d, document.getElementById("top-five-techs-last-week"));
                        }
            });
        

                                                                    } 
                                                         
                                            }
        );
   });   

   function paint_top_techs(d, target)
   {
        var tech_item = _.template($("#tmpl-top-tech-this-week").html());
        var tech_block = _.template($("#tmpl-tech-block").html());

        // FIXME: this is inserting divs asynchronously.  Needs synchronization
        var store = new Array(20);
        for (var i=0 ; i < 20 ; i++)
        {
           var rec = d[i];
           $(target).find("ol").append(tech_item({ name: rec.name, link: "tech" + (i + 1), change: rec.change }));
           $("a[data-id=tech" + (i + 1) + "]").html(rec.name); // Update the nav

           // Scoping...
           (function()
           {
             var idx = i;
             var node_name = "tech" + (idx + 1);
             var dataUrl = encodeURI("http://trends.taskboy.com/api/data/terms/" + rec.name + ".json");
             dataUrl = dataUrl.replace("#", "%23");
             // FIXME: the block needs to be in the DOM before this can get called
             // var changeUrl = encodeURL("http://trends.taskboy.com/api/data/changes/" + rec.name + ".json");

             var tech_block_data = {
                                   id: node_name,
                                   name: rec.name
                                   };   
             $.ajax({
                url : dataUrl,
                error: function()
                {
                  if ( idx == 19)
                  {
                    finish_tech_block_setup(store);
                  }

                },
                success: function(d)
                {
                  if (d)
                  {
                    tech_block_data.blurb = d.blurb;
                    tech_block_data.wikipedia_url = d.wikipedia_url;
                    tech_block_data.homepage = d.url;
                    store[idx] = tech_block(tech_block_data);
                  }

                  if ( idx == 19)
                  {
                    finish_tech_block_setup(store);
                  }
               }
             });
           })();
        }
  }

  function finish_tech_block_setup (store)
  {
        for (var i=0; i < store.length; i++)
        {
           $("#list-tech").append(store[i]);
           $("[data-role=six-week-tech]:last").each(function()
           {
                var term = $(this).attr("data-term");
                var six_week_url = encodeURI("http://trends.taskboy.com/api/data/changes/" + term + ".json");
                six_week_url = six_week_url.replace("#", "%23");
                $.ajax({
                        url: six_week_url,
                        success: function(d)
                        {
                           if (d)
                           {
                                var data = new google.visualization.DataTable();
                                data.addColumn("string", "Date");
                                data.addColumn("number", "Count");
                                for (var i=0; i < d.length - 1; i++) 
                                {
                                   var val = parseInt(d[i].count);
                                   var date = d[i].date;
                                   data.addRows([
                                                  [
                                                    date, val,
                                                  ]
                                   ]);
                                }

                                var options = {
                                    title : "",
                                    width: 500,
                                    height: 400,
                                    legend: 'none',
                                    curveType: 'function',
                                    colors: [ '#39f' ],
                                    vAxis: { ticks: 'none' },
                                    hAxis: { slantedText: true },
                                    chartArea: { top:20,right:0,bottom:0,left:60 },
                                };

                                var target = $("[data-term='" + term + "']").get(0);
                                if (target)
                                {
                                   var chart = new google.visualization.ColumnChart(target);
                                   chart.draw(data, options);
                                }
                                else
                                {       
                                  console.log("No target");
                                }       
                                
                           }
                        }
                });
           });
        }

        // add scroll functionality back
        $('.scroll-link').off('click').on('click', function(event)
        {
                event.preventDefault();
                var sectionID = $(this).attr("data-id");
                scrollToID('#' + sectionID, 750);
        });

        // scroll to top action
        $('.scroll-top').off('click').on('click', function(event) 
        {
                event.preventDefault();
                $('html, body').animate({scrollTop:0}, 'slow');                 
        });

        $('.scroll-agg').off('click').on('click', function(event) 
        {
                event.preventDefault();
                $('html, body').animate({scrollTop: $("#aggregates").offset().top }, 'slow');                 
        });
        
        // Clean up styling
        $("div[id^=tech]:even").addClass("inverse");
   }

   function paint_top_five_techs_chart(d, target)
   {
        var data = new google.visualization.DataTable();

        data.addColumn("string", "Technology");
        data.addColumn("number", "Count");

        for(var i=0; i < 5; i++)
        {
           var val = parseInt(d[i].count);
           var tech = d[i].name;
           data.addRows([
                          [
                            tech, val,
                          ]
                        ]);
        }

        var options = {
                        title : "Top 5 Techs",
                        width: 500,
                        height: 400,
                        pieStartAngle: 90,
                        legend: 'none',
                        pieSliceText: 'label',
                        chartArea: { top:0,right:0,bottom:0,left:0 },
                        slices: {
                                0: { color: '#39f' },
                                1: { color: '#99f' },
                                2: { color: '#93f' },
                                3: { color: '#f9f' },
                                4: { color: '#f39' },
                                5: { color: '#f66' },
                        }
                     };

        if (target)
        {
                var chart = new google.visualization.PieChart(target);
                chart.draw(data, options);
        }
        else
        {       
           console.log("No target");
        }       
   }      

   function paint_all_trends_chart(d, target)
   {
        var data = new google.visualization.DataTable();
        data.addColumn("string", "Technology");
        data.addColumn("number", "Count");
        for(var i=0; i < d.length; i++)
        {
           var val = parseInt(d[i].confidence);
           var tech = d[i].name;
           data.addRows([
                          [
                            tech, val,
                          ]
                        ]);
        }

        var options = {
                        title : "All Project Activity",
                        width: 250,
                        height: 500,
                     };

        if (target)
        {
                var chart = new google.visualization.BarChart(target);
                chart.draw(data, options);
        }
        else
        {       
           console.log("No target");
        }       
   }



});