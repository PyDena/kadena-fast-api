(module fractals "free.fractals-admin-keyset"
  @doc
  "'fractals' represents the Fractals.kda Contract"
  
  (defcap ADMIN ()
    @doc
      "only the ADMIN can perform certain actions"
    (enforce-guard (keyset-ref-guard "free.fractals-admin-keyset"))
    )

  (defschema count_schema
    count:integer
    max_num:integer
    )

  (deftable count_table:{count_schema} 
    )
  
  (defun get_table_count (name_of_table:string)
    (with-read count_table name_of_table {"count":=count}
      (count))
    )

  (defun increment_table_count (name_of_table:string)
    (with-capability (ADMIN)
      (with-read count_table name_of_table {"count":=count, "max_num":=max_num}
        
        (enforce (>= (max_num (+ count 1))))
        
        (write count_table name_of_table {"count": (+ count 1)}
          )
        (count)
        )
      )
    )
  
  
  ;fracal zoom variables for origin mandlebrot sets
  (defconst origin_X1 0.8) ; < center x
  (defconst origin_X2 2.5) ; > center x
  (defconst origin_Y1 0.5) ; < center y
  (defconst origin_Y2 2.5) ; > center y
  
  (defschema origin_sales_schema
    for_sale:bool
    price:decimal
    )

  (defschema origin_increment_schema
    r:decimal ;r value of foreground color increment
    g:decimal ;g value of foreground color increment
    b:decimal ;b value of foreground color increment
    p:integer ;ingcrement power level (used for combining fractals)
    )

  (defschema origin_background_schema
    r:decimal ;background r color value
    g:decimal ;background g color value
    b:decimal ;background b color value
    p:integer ;background power level (used for combining fractals)
    )

  (defschema origin_foreground_schema
    r:decimal ;foreground r color value
    g:decimal ;foreground g color value
    b:decimal ;foreground b color value
    p:integer ;foreground power level (used for combining fractals)
    )

  (defschema origin_schema
    owner:string
    created_on:time
    )
  
  (deftable origin_sales:{origin_sales_schema})
  (deftable origin_increment:{origin_increment_schema})
  (deftable origin_background:{origin_background_schema})
  (deftable origin_foreground:{origin_foreground_schema})
  (deftable origin:{origin_schema})

  (defun read_rgbp_table (id name_of_table:string)
   (with-read name_of_table id {"r":=r, "g":=g, "b":=b, "p":=p}
    {"r":r, "g":g, "b":b, "p":p}))

  (defun read_origin_nft (id)
    (with-read origin id {"owner" := owner, "created_on" := created_on}
      (with-read origin_sales id {"for_sale":=for_sale, "price":=price}
        
      {"id":id,
      "owner":owner,
      "created_on":created_on,
      "for_sale":for_sale,
      "price": price,
      "increment":(read_rgbp_table id "increment"),
      "background":(read_rgbp_table id "background"),
      "foreground":(read_rgbp_table id "foreground")})))

  (defun mint_origin_nft (increment:object background:object foreground:object)
    (with-capability (ADMIN)
      (let ((id (increment_table_count "origin")))

        (insert origin id
          {"owner":"k:1d02daf91a1997ca51abe5e0a6d2dea551388996d88c00e872273313a8fcdbb7", "created_on": (at "block-time" (chain-data))})

        (insert origin_increment id
            increment)

        (insert origin_background id
            background)

        (insert origin_foreground id
            foreground)

        (insert origin_sales id
            {"for_sale":true, "price":1000})
        
        (format "Created Origin # {}" [id]))
      )
    )
  )

