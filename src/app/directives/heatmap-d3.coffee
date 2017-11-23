app.directive 'heatmapD3', ()->
  restrict: 'E'
  scope: {
    data: '=',
    rowName: '=',
    colName: '=',
  },
  link: ($scope, element, attrs)->
    buildHeatmap = (data, field1, field2)->
      heatMapSvg.selectAll('*').remove()
      
      if !data.length
        updateColorBar('', '')
        return
      
      indexes = d3.set($scope.data.map((d) -> d[field1])).values()
      columns = d3.set($scope.data.map((d) -> d[field2])).values()

      columnValues = {}
      indexesValues = {}

      $scope.data.forEach (d)->
        name = d[field2]
        if !columnValues[name]
          columnValues[name] =0 
        columnValues[name] += d['value']

        name = d[field1]
        if !indexesValues[name]
          indexesValues[name] = 0
        indexesValues[name] += d['value']

      indexes = _.reverse(_.sortBy indexes, (d) -> indexesValues[d])
      columns = _.reverse(_.sortBy columns, (d) -> columnValues[d])

      xScale = d3.scale.ordinal()
               .domain(columns)
               .rangeBands([0, columns.length * itemSize.width]);

      yScale = d3.scale.ordinal()
               .domain(indexes)
               .rangeBands([0, indexes.length * itemSize.height]);

      # minValue = d3.min(data.map (d)-> d.value)
      maxValue = d3.max(data.map (d)-> d.value)
      
      tScale = d3.scale.linear()
                 .domain([0, baseColors.length - 1])
                 .range([0, maxValue])

      valuesRange = _.range(0, baseColors.length).map (x)-> tScale(x)

      colorScale = d3.scale.linear()
                   .domain(valuesRange)
                   .range(baseColors)

      xAxis = d3.svg.axis()
        .scale(xScale)
        .tickFormat((d) -> d)
        .orient("top");

      yAxis = d3.svg.axis()
        .scale(yScale)
        .tickFormat((d) -> d)
        .orient("left")

      heatMapSvg.append('rect')
        .attr('class', 'back')
        .attr('x', 0)
        .attr('y', 0)
        .attr('width', columns.length * itemSize.width)
        .attr('height', indexes.length * itemSize.height)
        .attr('fill', colorScale(0))

      heatMapSvg.selectAll('rect.cell')
        .data(data)
        .enter()
        .append('rect')
        .attr('class', 'cell')
        .attr('x', (d)-> xScale(d[field2]))
        .attr('y', (d)-> yScale(d[field1]))
        .attr('fill', (d)-> colorScale(d.value))
        .attr('width', itemSize.width)
        .attr('height', itemSize.height)

      heatMapSvg.append("g")
        .attr("class", "x axis")
        .call(xAxis)
        .selectAll('text')
        .attr('font-weight', 'normal')
        .style("text-anchor", "start")
        .attr("dx", ".8em")
        .attr("dy", ".5em")
        .attr("transform", (d) -> "rotate(-65)")

      heatMapSvg.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .selectAll('text')
        .attr('font-weight', 'normal')

      updateColorBar(0, maxValue)

    buildColorBar = ()->
      colorScale = d3.scale.linear()
                     .domain(_.range(0, baseColors.length - 1))
                     .range(baseColors)

     
      colorBarSvg.selectAll('rect.color-bar')
        .data(_.range(0, baseColors.length - 1))
        .enter()
        .append('rect')
        .attr('class', 'color-bar')
        .attr('width', itemSize.width)
        .attr('height', itemSize.height)
        .attr('x', (d) -> d * itemSize.width)
        .attr('y', 0)
        .attr('fill', (d) -> colorScale(d))


      colorBarSvg.selectAll('text.color-bar')
        .data([0, 1])
        .enter()
        .append('text')
        .attr('class', 'color-bar')
        .attr('x', (d, i)-> i * ((baseColors.length - 2) * itemSize.width))
        .attr('y', itemSize.height)
        .attr('dy', 15)
        .attr('dx', 4)
      
      return

    updateColorBar = (minValue, maxValue)->
      f = d3.format('.0%')
      selection = colorBarSvg.selectAll('text.color-bar')
        .data([minValue, maxValue])
        .text((d) -> d)

    baseColors = [
      '#fff5eb',
      '#fee6ce',
      '#fdd0a2',
      '#fdae6b',
      '#fd8d3c',
      '#f16913',
      '#d94801',
      '#a63603',
      '#7f2704',
    ]

    itemSize = {
      width: attrs.itemWidth
      height: attrs.itemHeight
    }
      
    $scope.$watch 'data', ()->
      buildHeatmap($scope.data, $scope.rowName, $scope.colName)

    rootSvg = d3.select(element[0])
              .append('svg')
              .attr('width', attrs.width)
              .attr('height', attrs.height)
    heatMapSvg = rootSvg.append('g')
                   .attr("transform", "translate(" + attrs.marginLeft + "," + attrs.marginTop + ")")

    colorBarSvg = rootSvg.append('g')
    buildColorBar()
