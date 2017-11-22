var app, appDependencies;

appDependencies = ['ngRoute', 'once'];

app = angular.module('app', appDependencies).config([
  '$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
    $routeProvider.when('/', {
      controller: 'MainController as main',
      templateUrl: 'pages/main.html'
    }).otherwise({
      redirectTo: '/'
    });
    $locationProvider.html5Mode(true);
  }
]);

app.controller('MainController', function($scope, $timeout, abundanceCalculator, topFiveGenerator, dataLoader, tools) {
  var parseData;
  $scope.initializing = true;
  parseData = function(error, rawData) {
    var ageIntervals, filteringFields, i, len, ref, s, samplesGeneAbundances, samplesSubstanceAbundances;
    $scope.mapData = rawData[0];
    $scope.data = {};
    $scope.data.countries = rawData[1];
    $scope.data.countriesCodeByName = {};
    $scope.data.countries.forEach(function(c) {
      return $scope.data.countriesCodeByName[c['name']] = c['code'];
    });
    $scope.data.substances = _.values(rawData[3].categories).map(function(substance) {
      return {
        name: substance['category_name'],
        resistance: substance['group'],
        genes: substance['genes'].map(function(g) {
          return g['gene_name'];
        }),
        infoLink: substance['info_link']
      };
    });
    $scope.data.resistances = {};
    _.uniq(_.map($scope.data.substances, 'resistance')).sort(tools.sortAlphabeticaly).forEach(function(resistance) {
      var resistanceSubstances;
      resistanceSubstances = $scope.data.substances.filter(function(s) {
        return s.resistance === resistance;
      });
      $scope.data.resistances[resistance] = _.uniq(_.map(resistanceSubstances, 'name')).sort(tools.sortAlphabeticaly);
    });
    abundanceCalculator.init($scope.data.resistances);
    topFiveGenerator.init($scope.data.substances);
    $scope.data.samples = _.values(rawData[2]);
    samplesSubstanceAbundances = _.groupBy(rawData[4], 'sample');
    samplesGeneAbundances = _.groupBy(rawData[5], 'sample');
    $scope.sampleGeneTaxa = rawData[7];
    ref = $scope.sampleGeneTaxa;
    for (i = 0, len = ref.length; i < len; i++) {
      s = ref[i];
      s.sampleLower = s.sample.toLowerCase();
      s.gene_idLower = s.gene_id.toLowerCase();
    }
    $scope.data.samples.forEach(function(sample) {
      var resistances, sName, sampleGeneAbundances, sampleSubstanceAbundances;
      sample.genes = {};
      if (sample['f-genders'] !== 'NA') {
        sample['f-genders'] = _.capitalize(_.head(sample['f-genders']));
      }
      sName = sample['names'];
      sampleSubstanceAbundances = _.groupBy(samplesSubstanceAbundances[sName], 'category');
      sampleGeneAbundances = _.groupBy(samplesGeneAbundances[sName], 'category');
      _.forIn(sampleGeneAbundances, function(value, key) {
        sampleGeneAbundances[key] = _.groupBy(value, 'gene id');
      });
      resistances = _.keys($scope.data.resistances);
      resistances.forEach(function(r) {
        var resistanceSubstances;
        resistanceSubstances = $scope.data.resistances[r];
        sample[r] = {};
        resistanceSubstances.forEach(function(s) {
          var rec, ref1, substanceGenes;
          rec = (ref1 = sampleSubstanceAbundances[s]) != null ? ref1[0] : void 0;
          sample[r][s] = !rec ? 0 : parseFloat(rec['sum_abund']);
          substanceGenes = _.find($scope.data.substances, {
            'name': s
          })['genes'];
          sample.genes[s] = {};
          substanceGenes.forEach(function(g) {
            var ref2, ref3;
            rec = (ref2 = sampleGeneAbundances[s]) != null ? (ref3 = ref2[g]) != null ? ref3[0] : void 0 : void 0;
            sample.genes[s][g] = !rec ? 0 : parseFloat(rec['abund']);
          });
        });
      });
    });
    $scope.studies = rawData[6].map(function(d) {
      return {
        name: d['study'],
        link: d['link to article'],
        reads: d['links to reads']
      };
    }).sort(function(a, b) {
      return tools.sortAlphabeticaly(a.name, b.name);
    });
    filteringFields = ['f-studies', 'f-countries', 'f-diagnosis', 'f-genders', 'f-ages'];
    ageIntervals = ['0...9', '10...16', '17...25', '26...35', '36...50', '51...70', '71...∞'];
    $scope.data.ageIntervalsIndexed = ageIntervals.map(function(intervalStr) {
      var begin, end, ref1;
      ref1 = intervalStr.split('...'), begin = ref1[0], end = ref1[1];
      begin = parseInt(begin);
      end = end === '∞' ? 2e308 : parseInt(end);
      return [begin, end, intervalStr];
    });
    $scope.data.filteringFieldsValues = {};
    $scope.data.flags = {};
    filteringFields.forEach(function(ff) {
      if (ff === 'f-ages') {
        $scope.data.filteringFieldsValues[ff] = ageIntervals;
      } else {
        $scope.data.filteringFieldsValues[ff] = _.uniq(_.map($scope.data.samples, ff)).sort(tools.sortAlphabeticaly);
      }
      if (ff === 'f-studies' || ff === 'f-countries') {
        $scope.data.filteringFieldsValues[ff].forEach(function(v) {
          var ffCountries;
          if (ff === 'f-countries') {
            $scope.data.flags[v] = [
              _.find($scope.data.countries, {
                'name': v
              })['code']
            ];
          } else {
            ffCountries = _.groupBy($scope.data.samples, ff)[v].map(function(s) {
              return s['f-countries'];
            });
            $scope.data.flags[v] = _.uniq(ffCountries).map(function(c) {
              return _.find($scope.data.countries, {
                'name': c
              })['code'];
            });
          }
        });
      }
    });
    $scope.initializing = false;
    $scope.$apply();
    likely.initiate();
    $timeout(function() {
      return $('.loading-cover').fadeOut();
    }, 500);
  };
  dataLoader.getData().awaitAll(parseData);
});

app.directive('customSelectMulti', function($document, $timeout) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/custom-select-multi.html',
    scope: {
      key: '=',
      dataset: '=',
      plural: '=',
      selected: '=',
      flagsBefore: '='
    },
    link: function($scope, $element, $attrs) {
      var clickHandler;
      clickHandler = function(event) {
        if ($element.find(event.target).length) {
          return;
        }
        $scope.isListShown = false;
        $scope.$apply();
        $document.unbind('click', clickHandler);
      };
      $scope.toggleList = function() {
        $scope.isListShown = !$scope.isListShown;
        if ($scope.isListShown) {
          $document.bind('click', clickHandler);
        } else {
          $document.unbind('click', clickHandler);
        }
      };
      $scope.isItemSelected = function(item) {
        var index;
        index = _.indexOf(_.map($scope.selected, 'title'), item.title);
        return index !== -1;
      };
      $scope.selectItem = function(item) {
        var index;
        index = _.indexOf(_.map($scope.selected, 'title'), item.title);
        if (index !== -1) {
          $scope.selected.splice(index, 1);
        } else {
          $scope.selected.push(item);
        }
      };
      $timeout(function() {
        var $dropdown, $toggle, dropdownHasScroll, dropdownWidth, toggleWidth;
        $toggle = $element.find('.custom-select-multi__toggle');
        $dropdown = $element.find('.custom-select-multi__dropdown');
        toggleWidth = $toggle[0].getBoundingClientRect().width;
        dropdownWidth = $dropdown[0].getBoundingClientRect().width;
        dropdownHasScroll = $dropdown[0].scrollHeight > $dropdown[0].offsetHeight;
        if (dropdownHasScroll) {
          dropdownWidth += 16;
        }
        $toggle.innerWidth(Math.max(toggleWidth, dropdownWidth));
        $dropdown.width(Math.max(toggleWidth, dropdownWidth));
        $scope.isSelectPrepared = true;
      });
    }
  };
});

app.directive('customSelect', function($document, $timeout) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/custom-select.html',
    scope: {
      key: '=',
      dataset: '=',
      selected: '='
    },
    link: function($scope, $element, $attrs) {
      var clickHandler;
      clickHandler = function(event) {
        if ($element.find(event.target).length) {
          return;
        }
        $scope.isListShown = false;
        $scope.$apply();
        $document.unbind('click', clickHandler);
      };
      $scope.toggleList = function() {
        $scope.isListShown = !$scope.isListShown;
        if ($scope.isListShown) {
          $document.bind('click', clickHandler);
        } else {
          $document.unbind('click', clickHandler);
        }
      };
      $scope.isItemSelected = function(item) {
        return $scope.selected.title === item.title;
      };
      $scope.selectItem = function(item) {
        $scope.selected = item;
        $scope.isListShown = false;
      };
      $timeout(function() {
        var $dropdown, $toggle, dropdownHasScroll, dropdownWidth, toggleWidth;
        $toggle = $element.find('.custom-select__toggle');
        $dropdown = $element.find('.custom-select__dropdown');
        toggleWidth = $toggle[0].getBoundingClientRect().width;
        dropdownWidth = $dropdown[0].getBoundingClientRect().width;
        dropdownHasScroll = $dropdown[0].scrollHeight > $dropdown[0].offsetHeight;
        if (dropdownHasScroll) {
          dropdownWidth += 16;
        }
        $toggle.innerWidth(Math.max(toggleWidth, dropdownWidth));
        $dropdown.width(Math.max(toggleWidth, dropdownWidth));
        $scope.isSelectPrepared = true;
      });
    }
  };
});

app.directive('filters', function($rootScope) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/filters.html',
    scope: {
      data: '='
    },
    link: function($scope, $element, $attrs) {
      var filteringFields, onGroupingChanged;
      filteringFields = ['f-studies', 'f-countries'];
      $scope.studyCountryFilters = [];
      $scope.studyCountryFiltersValues = {};
      filteringFields.forEach(function(ff) {
        var dataset, filter;
        dataset = $scope.data.filteringFieldsValues[ff].map(function(u) {
          return {
            title: u,
            value: u,
            flags: $scope.data.flags[u]
          };
        });
        filter = {
          key: ff,
          dataset: dataset,
          plural: ff.split('-')[1],
          flagsBefore: ff === 'f-countries'
        };
        $scope.studyCountryFilters.push(filter);
        $scope.studyCountryFiltersValues[ff] = [];
      });
      $scope.resetFilters = function() {
        _.keys($scope.studyCountryFiltersValues).forEach(function(key) {
          $scope.studyCountryFiltersValues[key] = [];
        });
      };
      $scope.checkboxes = _.keys($scope.data.filteringFieldsValues);
      $scope.checkboxesValues = {};
      $scope.checkboxes.forEach(function(c) {
        $scope.checkboxesValues[c] = c === 'f-countries';
      });
      $scope.sortBySelect = {
        key: 'sort-by',
        dataset: [
          {
            title: 'number of samples',
            value: false
          }, {
            title: 'resistance level',
            value: true
          }
        ]
      };
      $scope.sortBySelectValue = $scope.sortBySelect.dataset[0];
      onGroupingChanged = function() {
        var eventData;
        eventData = {
          studyCountryFiltersValues: $scope.studyCountryFiltersValues,
          checkboxesValues: $scope.checkboxesValues
        };
        $rootScope.$broadcast('filters.groupingChanged', eventData);
      };
      $scope.$watch('studyCountryFiltersValues', function() {
        var eventData;
        eventData = {};
        _.keys($scope.studyCountryFiltersValues).forEach(function(key) {
          eventData[key] = $scope.studyCountryFiltersValues[key].map(function(fv) {
            return fv.value;
          });
        });
        $scope.isResetShown = _.some(_.keys(eventData), function(key) {
          return eventData[key].length;
        });
        $rootScope.$broadcast('filters.filtersChanged', eventData);
        onGroupingChanged();
      }, true);
      $scope.$watch('checkboxesValues', function() {
        onGroupingChanged();
      }, true);
      $scope.$watch('sortBySelectValue', function() {
        $rootScope.$broadcast('filters.sortingStateChanged', $scope.sortBySelectValue.value);
      });
    }
  };
});

app.directive('heatmapChart', function($rootScope, abundanceCalculator, topFiveGenerator, colorScale, samplesFilter, tools) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/heatmap-chart.html',
    scope: {
      data: '='
    },
    link: function($scope, $element, $attrs) {
      var checkboxesValues, createCohorts, createExcelbuilderCell, getCohortAbundances, getPermutationsCohorts, prepareCellData, studyCountryFiltersValues;
      $scope.predicate = {};
      $scope.reverseSorting = true;
      studyCountryFiltersValues = void 0;
      checkboxesValues = void 0;
      getCohortAbundances = function(samples) {
        var cohortAbundances;
        cohortAbundances = {};
        _.keys($scope.data.resistances).forEach(function(key) {
          var resistanceSubstances;
          cohortAbundances[key] = {
            overall: abundanceCalculator.getAbundanceValue(samples, key, 'overall')
          };
          resistanceSubstances = $scope.data.resistances[key];
          if (!(resistanceSubstances.length > 1)) {
            return;
          }
          resistanceSubstances.forEach(function(s) {
            cohortAbundances[key][s] = abundanceCalculator.getAbundanceValue(samples, key, s);
          });
        });
        return cohortAbundances;
      };
      getPermutationsCohorts = function(samples, order) {
        var _cohortSamples, _displayedOrders, _permutationsCohorts, nOfGroupSamples, permutations, permutationsCohorts, sortingEnabled;
        permutationsCohorts = [];
        permutations = tools.getPermutations(order.map(function(o) {
          return $scope.data.filteringFieldsValues[o];
        }));
        nOfGroupSamples = {};
        sortingEnabled = $scope.predicate.resistance && $scope.predicate.substance;
        _.uniq(permutations.map(function(p) {
          return p[0];
        })).forEach(function(u) {
          var groupProperties;
          groupProperties = {};
          groupProperties[order[0]] = u;
          nOfGroupSamples[u] = samplesFilter.getFilteredSamples(samples, groupProperties).length;
        });
        _cohortSamples = {};
        _cohortSamples = _.groupBy(samples, function(s) {
          var props;
          props = order.map(function(o) {
            if (o !== 'f-ages') {
              return s[o];
            } else {
              return tools.searchInIndexedIntervals($scope.data.ageIntervalsIndexed, s[o]);
            }
          });
          return props.join('::');
        });
        _displayedOrders = order.filter(function(p) {
          return p !== 'f-genders' && (order.length === 1 || p !== 'f-countries');
        });
        _permutationsCohorts = _.map(_cohortSamples, function(cohortSamples, order_str) {
          var cohortProperties, displayName, displayNameTokens, permutation;
          permutation = order_str.split('::');
          cohortProperties = _.zipObject(order, permutation);
          displayNameTokens = _displayedOrders.map(function(o) {
            return cohortProperties[o];
          });
          displayName = displayNameTokens.join(', ');
          return {
            permutation: permutation,
            name: permutation,
            displayName: displayName,
            flag: $scope.data.countriesCodeByName[cohortProperties['f-countries']],
            gender: cohortProperties['f-genders'],
            samples: cohortSamples,
            nOfSamplesInGroup: nOfGroupSamples[permutation[0]],
            abundances: getCohortAbundances(cohortSamples)
          };
        });
        _permutationsCohorts.sort(function(a, b) {
          var aa, ba;
          if (!sortingEnabled) {
            if (a.nOfSamplesInGroup < b.nOfSamplesInGroup) {
              return 1;
            }
            if (a.nOfSamplesInGroup > b.nOfSamplesInGroup) {
              return -1;
            }
            if (a.name > b.name) {
              return 1;
            }
            if (a.name < b.name) {
              return -1;
            }
            return 0;
          } else {
            aa = a.abundances[$scope.predicate.resistance][$scope.predicate.substance];
            ba = b.abundances[$scope.predicate.resistance][$scope.predicate.substance];
            return (aa === ba ? 0 : aa < ba ? -1 : 1) * ($scope.reverseSorting ? -1 : 1);
          }
        });
        if (!sortingEnabled) {
          _permutationsCohorts.forEach(function(p, i) {
            var isPushed, previousCohort;
            previousCohort = _permutationsCohorts[i - 1];
            isPushed = false;
            if (previousCohort) {
              isPushed = _.some(_.dropRight(order, 1), function(o, j) {
                return p.permutation[j] !== previousCohort.permutation[j];
              });
            }
            p.isPushed = isPushed;
          });
        }
        return _permutationsCohorts;
      };
      createCohorts = function() {
        var countries, groupingOrder, rootCohorts, roots, sortingEnabled, studies;
        $scope.cohorts = [];
        sortingEnabled = $scope.predicate.resistance && $scope.predicate.substance;
        studies = studyCountryFiltersValues['f-studies'].map(function(fv) {
          return fv.value;
        });
        countries = studyCountryFiltersValues['f-countries'].map(function(fv) {
          return fv.value;
        });
        groupingOrder = _.keys(checkboxesValues).filter(function(key) {
          return checkboxesValues[key] && (studies.length ? key !== 'f-studies' : true) && (countries.length ? key !== 'f-countries' : true);
        });
        if (studies.length || countries.length) {
          roots = [];
          if (studies.length && countries.length) {
            roots = tools.getPermutations([studies, countries]);
          } else if (studies.length) {
            roots = studies;
          } else {
            roots = countries;
          }
          rootCohorts = [];
          roots.forEach(function(root, i) {
            var displayName, flag, name, rootProperties, rootSamples;
            rootProperties = {};
            if (_.isArray(root)) {
              rootProperties['f-studies'] = root[0];
              rootProperties['f-countries'] = root[1];
            } else {
              rootProperties[studies.length ? 'f-studies' : 'f-countries'] = root;
            }
            rootSamples = samplesFilter.getFilteredSamples($scope.data.samples, rootProperties);
            if (!rootSamples.length) {
              return;
            }
            flag = countries.length ? _.find($scope.data.countries, {
              'name': rootProperties['f-countries']
            })['code'] : void 0;
            name = root;
            displayName = _.isArray(root) ? root[0] : root;
            rootCohorts.push({
              name: name,
              displayName: displayName,
              flag: flag,
              samples: rootSamples,
              abundances: getCohortAbundances(rootSamples)
            });
          });
          rootCohorts.sort(function(a, b) {
            var aa, ba;
            if (!sortingEnabled) {
              if (a.samples.length < b.samples.length) {
                return 1;
              }
              if (a.samples.length > b.samples.length) {
                return -1;
              }
              if (a.name > b.name) {
                return 1;
              }
              if (a.name < b.name) {
                return -1;
              }
              return 0;
            } else {
              aa = a.abundances[$scope.predicate.resistance][$scope.predicate.substance];
              ba = b.abundances[$scope.predicate.resistance][$scope.predicate.substance];
              return (aa === ba ? 0 : aa < ba ? -1 : 1) * ($scope.reverseSorting ? -1 : 1);
            }
          }).forEach(function(root, i) {
            var permutationsCohorts;
            root.isPushed = i;
            $scope.cohorts.push(root);
            permutationsCohorts = getPermutationsCohorts(root.samples, groupingOrder);
            if (!permutationsCohorts.length) {
              return;
            }
            permutationsCohorts[0].isPushed = true;
            $scope.cohorts = $scope.cohorts.concat(permutationsCohorts);
          });
        } else {
          $scope.cohorts = getPermutationsCohorts($scope.data.samples, groupingOrder);
        }
      };
      $scope.getCellColor = function(cohort, resistance, substance) {
        return colorScale.getColorByValue(cohort.abundances[resistance][substance]);
      };
      createExcelbuilderCell = function(value, type, format) {
        return {
          value: value,
          metadata: {
            type: type,
            style: format
          }
        };
      };
      $scope.downloadData = function() {
        var $a, file, fileData, formats, sheet, stylesheet, workbook;
        $a = $('.heatmap-chart__download a');
        workbook = ExcelBuilder.createWorkbook();
        sheet = workbook.createWorksheet({
          name: 'Sheet'
        });
        stylesheet = workbook.getStyleSheet();
        formats = {
          header: stylesheet.createFormat({
            font: {
              bold: true
            }
          })
        };
        fileData = [];
        $scope.cohorts.forEach(function(c, i) {
          var cohortRow, firstRow, secondRow;
          cohortRow = [];
          cohortRow.push(createExcelbuilderCell(c.name, 'string'));
          cohortRow.push(createExcelbuilderCell(c.samples.length, 'number'));
          if (!i) {
            firstRow = [];
            secondRow = [];
            firstRow.push(createExcelbuilderCell('', 'string'));
            firstRow.push(createExcelbuilderCell('', 'string'));
            secondRow.push(createExcelbuilderCell('Cohort', 'string'));
            secondRow.push(createExcelbuilderCell('Samples', 'string'));
          }
          _.keys($scope.data.resistances).forEach(function(key) {
            ['overall'].concat(($scope.data.resistances[key].length < 2 ? [] : $scope.data.resistances[key])).forEach(function(substance, j) {
              if (!i) {
                if (!j) {
                  firstRow.push(createExcelbuilderCell('', 'string'));
                  firstRow.push(createExcelbuilderCell(key, 'string', formats.header.id));
                } else {
                  firstRow.push(createExcelbuilderCell('', 'string'));
                }
                if (!j) {
                  secondRow.push(createExcelbuilderCell('', 'string'));
                }
                secondRow.push(createExcelbuilderCell((substance === 'overall' ? ($scope.data.resistances[key].length < 2 ? 'median' : 'mean') : substance), 'string'));
              }
              if (!j) {
                cohortRow.push(createExcelbuilderCell('', 'string'));
              }
              cohortRow.push(createExcelbuilderCell(c.abundances[key][substance], 'number'));
            });
          });
          if (!i) {
            fileData.push(firstRow);
            fileData.push(secondRow);
          }
          if (c.isPushed) {
            fileData.push([]);
          }
          fileData.push(cohortRow);
        });
        sheet.setData(fileData);
        workbook.addWorksheet(sheet);
        file = ExcelBuilder.createFile(workbook);
        $a.attr('download', 'Heatmap.xlsx').attr('href', 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,' + file);
      };
      prepareCellData = function(cohort, resistance, substance) {
        var ref;
        return {
          countryName: (ref = _.find($scope.data.countries, {
            'code': cohort.flag
          })) != null ? ref['name'] : void 0,
          flag: cohort.flag,
          abundanceValue: cohort.abundances[resistance][substance],
          abundanceValueType: resistance.indexOf('ABX') !== -1 && substance === 'overall' ? 'Mean' : 'Median',
          nOfSamples: cohort.samples.length,
          samples: cohort.samples,
          resistance: resistance,
          substance: substance,
          topFiveList: topFiveGenerator.get(cohort.samples, cohort.abundances, resistance, substance)
        };
      };
      $scope.substanceMouseOver = function(cohort, resistance, substance) {
        $scope.tempResistance = resistance;
        $scope.tempSubstance = substance;
        if (cohort) {
          $rootScope.$broadcast('heatmapChart.cellChanged', prepareCellData(cohort, resistance, substance));
        }
        $rootScope.$broadcast('heatmapChart.tempSubstanceChanged', substance === 'overall' ? resistance : substance);
      };
      $scope.substanceMouseOut = function() {
        $scope.tempResistance = void 0;
        $scope.tempSubstance = void 0;
        $rootScope.$broadcast('heatmapChart.cellChanged', {});
        $rootScope.$broadcast('heatmapChart.tempSubstanceChanged', void 0);
      };
      $scope.substanceMouseClick = function(cohort, resistance, substance, isSortable) {
        $scope.defaultResistance = resistance;
        $scope.defaultSubstance = substance;
        if (cohort) {
          if ($scope.frozenCell && $scope.frozenCell.cohort === cohort && $scope.frozenCell.resistance === resistance && $scope.frozenCell.substance === substance) {
            $scope.frozenCell = void 0;
            $rootScope.$broadcast('heatmapChart.cellIsUnfrozen');
          } else {
            $scope.frozenCell = {
              cohort: cohort,
              resistance: resistance,
              substance: substance
            };
            $rootScope.$broadcast('heatmapChart.cellIsFrozen');
            $rootScope.$broadcast('heatmapChart.cellChanged', prepareCellData(cohort, resistance, substance), true);
          }
        } else {
          $scope.frozenCell = void 0;
          $rootScope.$broadcast('heatmapChart.cellIsUnfrozen');
          $rootScope.$broadcast('heatmapChart.cellChanged', {});
          if ($scope.predicate.resistance && $scope.predicate.substance) {
            if (isSortable) {
              if ($scope.predicate.resistance === resistance && $scope.predicate.substance === substance) {
                $scope.reverseSorting = !$scope.reverseSorting;
              } else {
                $scope.reverseSorting = true;
              }
            }
            $scope.predicate.resistance = resistance;
            $scope.predicate.substance = substance;
            createCohorts();
          }
        }
        $rootScope.$broadcast('heatmapChart.defaultSubstanceChanged');
      };
      $scope.$on('substanceFilter.defaultSubstanceChanged', function(event, eventData) {
        $scope.frozenCell = void 0;
        $scope.defaultResistance = eventData.resistance ? eventData.resistance : eventData.substance;
        $scope.defaultSubstance = eventData.resistance ? eventData.substance : 'overall';
      });
      $scope.$on('filters.groupingChanged', function(event, eventData) {
        studyCountryFiltersValues = eventData.studyCountryFiltersValues;
        checkboxesValues = eventData.checkboxesValues;
        createCohorts();
      });
      $scope.$on('filters.sortingStateChanged', function(event, eventData) {
        $scope.predicate.resistance = eventData ? $scope.defaultResistance : void 0;
        $scope.predicate.substance = eventData ? $scope.defaultSubstance : void 0;
        createCohorts();
      });
    }
  };
});

app.directive('heatmapD3', function() {
  return {
    restrict: 'E',
    scope: {
      data: '=',
      rowName: '=',
      colName: '='
    },
    link: function($scope, element, attrs) {
      var baseColors, buildColorBar, buildHeatmap, colorBarSvg, heatMapSvg, itemSize, rootSvg, updateColorBar;
      buildHeatmap = function(data, field1, field2) {
        var colorScale, columnValues, columns, indexes, indexesValues, maxValue, tScale, valuesRange, xAxis, xScale, yAxis, yScale;
        heatMapSvg.selectAll('*').remove();
        if (!data.length) {
          return;
        }
        indexes = d3.set($scope.data.map(function(d) {
          return d[field1];
        })).values();
        columns = d3.set($scope.data.map(function(d) {
          return d[field2];
        })).values();
        columnValues = {};
        indexesValues = {};
        $scope.data.forEach(function(d) {
          var name;
          name = d[field2];
          if (!columnValues[name]) {
            columnValues[name] = 0;
          }
          columnValues[name] += d['value'];
          name = d[field1];
          if (!indexesValues[name]) {
            indexesValues[name] = 0;
          }
          return indexesValues[name] += d['value'];
        });
        indexes = _.reverse(_.sortBy(indexes, function(d) {
          return indexesValues[d];
        }));
        columns = _.reverse(_.sortBy(columns, function(d) {
          return columnValues[d];
        }));
        xScale = d3.scale.ordinal().domain(columns).rangeBands([0, columns.length * itemSize.width]);
        yScale = d3.scale.ordinal().domain(indexes).rangeBands([0, indexes.length * itemSize.height]);
        maxValue = d3.max(data.map(function(d) {
          return d.value;
        }));
        tScale = d3.scale.linear().domain([0, baseColors.length - 1]).range([0, maxValue]);
        valuesRange = _.range(0, baseColors.length).map(function(x) {
          return tScale(x);
        });
        colorScale = d3.scale.linear().domain(valuesRange).range(baseColors);
        xAxis = d3.svg.axis().scale(xScale).tickFormat(function(d) {
          return d;
        }).orient("top");
        yAxis = d3.svg.axis().scale(yScale).tickFormat(function(d) {
          return d;
        }).orient("left");
        heatMapSvg.append('rect').attr('class', 'back').attr('x', 0).attr('y', 0).attr('width', columns.length * itemSize.width).attr('height', indexes.length * itemSize.height).attr('fill', colorScale(0));
        heatMapSvg.selectAll('rect.cell').data(data).enter().append('rect').attr('class', 'cell').attr('x', function(d) {
          return xScale(d[field2]);
        }).attr('y', function(d) {
          return yScale(d[field1]);
        }).attr('fill', function(d) {
          return colorScale(d.value);
        }).attr('width', itemSize.width).attr('height', itemSize.height);
        heatMapSvg.append("g").attr("class", "x axis").call(xAxis).selectAll('text').attr('font-weight', 'normal').style("text-anchor", "start").attr("dx", ".8em").attr("dy", ".5em").attr("transform", function(d) {
          return "rotate(-65)";
        });
        heatMapSvg.append("g").attr("class", "y axis").call(yAxis).selectAll('text').attr('font-weight', 'normal');
        return updateColorBar(0, maxValue);
      };
      buildColorBar = function() {
        var colorScale;
        colorScale = d3.scale.linear().domain(_.range(0, baseColors.length - 1)).range(baseColors);
        colorBarSvg.selectAll('rect.color-bar').data(_.range(0, baseColors.length - 1)).enter().append('rect').attr('class', 'color-bar').attr('width', itemSize.width).attr('height', itemSize.height).attr('x', function(d) {
          return d * itemSize.width;
        }).attr('y', 0).attr('fill', function(d) {
          return colorScale(d);
        });
        colorBarSvg.selectAll('text.color-bar').data([0, 1]).enter().append('text').attr('class', 'color-bar').attr('x', function(d, i) {
          return i * ((baseColors.length - 2) * itemSize.width);
        }).attr('y', itemSize.height).attr('dy', 15).attr('dx', 4);
      };
      updateColorBar = function(minValue, maxValue) {
        var f, selection;
        f = d3.format('.0%');
        return selection = colorBarSvg.selectAll('text.color-bar').data([minValue, maxValue]).text(function(d) {
          return d;
        });
      };
      baseColors = ['#fff5eb', '#fee6ce', '#fdd0a2', '#fdae6b', '#fd8d3c', '#f16913', '#d94801', '#a63603', '#7f2704'];
      itemSize = {
        width: attrs.itemWidth,
        height: attrs.itemHeight
      };
      $scope.$watch('data', function() {
        return buildHeatmap($scope.data, $scope.rowName, $scope.colName);
      });
      rootSvg = d3.select(element[0]).append('svg').attr('width', attrs.width).attr('height', attrs.height);
      heatMapSvg = rootSvg.append('g').attr("transform", "translate(" + attrs.marginLeft + "," + attrs.marginTop + ")");
      colorBarSvg = rootSvg.append('g');
      return buildColorBar();
    }
  };
});

app.directive('infoBlock', function($rootScope, colorScale) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/info-block.html',
    link: function($scope, $element, $attrs) {
      var changeCellInfo, changeSubstanceInfo, getLegendPointerX, isFrozen, legendScaleRange, legendWidth;
      legendWidth = $element.find('.gradient').width();
      legendScaleRange = d3.range(0, legendWidth, legendWidth / (colorScale.getRange().length - 1));
      legendScaleRange.push(legendWidth);
      isFrozen = false;
      $scope.legendGradient = colorScale.getRange();
      $scope.legendPointerX = 0;
      $scope.legendScale = d3.scale.log().domain(colorScale.getDomain()).range(legendScaleRange);
      $scope.maxBarWidth = 76;
      getLegendPointerX = function(value) {
        if (!value) {
          return 0;
        } else {
          return $scope.legendScale(value);
        }
      };
      changeCellInfo = function(eventData) {
        $scope.countryName = eventData.countryName;
        $scope.flag = eventData.flag;
        $scope.abundanceValue = eventData.abundanceValue;
        $scope.abundanceValueType = eventData.abundanceValueType;
        $scope.nOfSamples = eventData.nOfSamples;
        $scope.topFiveList = eventData.topFiveList;
        $scope.legendPointerX = getLegendPointerX(eventData.abundanceValue);
      };
      changeSubstanceInfo = function(eventData) {
        $scope.substance = eventData.substance;
        $scope.infoLink = eventData.infoLink;
        $scope.database = eventData.database;
      };
      $scope.$on('substanceFilter.substanceChanged', function(event, eventData, ignoreFrozen) {
        if (isFrozen && !ignoreFrozen) {
          return;
        }
        changeSubstanceInfo(eventData);
      });
      $scope.$on('substanceFilter.defaultSubstanceChanged', function(event, eventData) {
        changeSubstanceInfo(eventData);
        changeCellInfo({});
        isFrozen = false;
      });
      $scope.$on('heatmapChart.cellChanged', function(event, eventData, ignoreFrozen) {
        if (isFrozen && !ignoreFrozen) {
          return;
        }
        changeCellInfo(eventData);
      });
      $scope.$on('mapChart.countryInOut', function(event, eventData) {
        if (isFrozen) {
          return;
        }
        changeCellInfo(eventData);
      });
      $scope.$on('heatmapChart.cellIsFrozen', function() {
        isFrozen = true;
      });
      $scope.$on('heatmapChart.cellIsUnfrozen', function() {
        isFrozen = false;
      });
      $scope.getBarColor = function(value) {
        return colorScale.getColorByValue(value);
      };
    }
  };
});

app.directive('mapChart', function($document, $rootScope, $timeout, abundanceCalculator, topFiveGenerator, colorScale, samplesFilter) {
  return {
    restrict: 'E',
    replace: true,
    template: '<div class="map-chart"></div>',
    scope: {
      data: '=',
      mapData: '='
    },
    link: function($scope, $element, $attrs) {
      var coordinates, countriesG, countryAbundances, countrySamples, d3element, g, goodZoom, height, maxZoom, minZoom, paintMap, pathGenerator, point, projection, reattach, recalcCountryAbundances, redrawMap, resistance, samplesCountries, strokeWidth, substance, svg, underlay, width, zoom, zoomFromOutside, zoomInCountries;
      d3element = d3.select($element[0]);
      height = $element.height();
      width = void 0;
      minZoom = void 0;
      goodZoom = void 0;
      maxZoom = void 0;
      strokeWidth = .5;
      reattach = function(element) {
        var parent;
        parent = element.parentNode;
        parent.removeChild(element);
        parent.appendChild(element);
      };
      projection = d3.geo.mercator().center([0, 44]).rotate([-11, 0]);
      pathGenerator = d3.geo.path().projection(projection);
      zoom = d3.behavior.zoom().on('zoom', function() {
        redrawMap(false);
      });
      redrawMap = function(withAnimation) {
        $rootScope.$broadcast('mapChart.canZoomIn', zoom.scale() !== maxZoom);
        $rootScope.$broadcast('mapChart.canZoomOut', zoom.scale() !== minZoom);
        projection.translate(zoom.translate()).scale(zoom.scale());
        if (!withAnimation) {
          d3element.selectAll('.country').attr('d', pathGenerator);
        } else {
          d3element.selectAll('.country').transition().duration(500).attr('d', pathGenerator);
        }
      };
      zoomInCountries = function(filteredSamples) {
        var countryCodes, dx, dy, newScale, newTranslate, returnToDefault, scale0, translate0, x, xMax, xMin, y, yMax, yMin;
        if (!width) {
          return;
        }
        returnToDefault = filteredSamples.length === $scope.data.samples.length || !filteredSamples.length;
        newScale = goodZoom;
        newTranslate = [width / 2, height / 2];
        if (!returnToDefault) {
          countryCodes = _.uniq(_.map(filteredSamples, 'f-countries')).map(function(name) {
            var country;
            country = _.find($scope.data.countries, {
              'name': name
            });
            return country.code;
          });
          xMin = 2e308;
          xMax = -2e308;
          yMin = 2e308;
          yMax = -2e308;
          d3element.selectAll('.country').filter(function(d) {
            return countryCodes.indexOf(d.id) !== -1;
          }).each(function(d) {
            var bounds;
            bounds = pathGenerator.bounds(d);
            xMin = Math.min(xMin, bounds[0][0]);
            xMax = Math.max(xMax, bounds[1][0]);
            yMin = Math.min(yMin, bounds[0][1]);
            yMax = Math.max(yMax, bounds[1][1]);
          });
          dx = xMax - xMin;
          dy = yMax - yMin;
          x = (xMin + xMax) / 2;
          y = (yMin + yMax) / 2;
          scale0 = zoom.scale();
          newScale = Math.max(minZoom, Math.min(maxZoom, .9 / Math.max(dx / width / scale0, dy / height / scale0)));
          translate0 = zoom.translate();
          newTranslate = [(translate0[0] - x) * newScale / scale0 + width / 2, (translate0[1] - y) * newScale / scale0 + height / 2];
        }
        zoom.translate(newTranslate).scale(newScale);
        redrawMap(true);
      };
      coordinates = function(point) {
        var scale, translate;
        scale = zoom.scale();
        translate = zoom.translate();
        return [(point[0] - translate[0]) / scale, (point[1] - translate[1]) / scale];
      };
      point = function(coordinates) {
        var scale, translate;
        scale = zoom.scale();
        translate = zoom.translate();
        return [coordinates[0] * scale + translate[0], coordinates[1] * scale + translate[1]];
      };
      zoomFromOutside = function(direction) {
        var center0, center1, coordinates0, translate0;
        center0 = [width / 2, height / 2];
        translate0 = zoom.translate();
        coordinates0 = coordinates(center0);
        zoom.scale(zoom.scale() * Math.pow(2, (direction === 'in' ? 1 : -1)));
        center1 = point(coordinates0);
        zoom.translate([translate0[0] + center0[0] - center1[0], translate0[1] + center0[1] - center1[1]]);
        redrawMap(true);
      };
      svg = d3element.append('svg').classed('map-chart__svg', true).attr('height', height).call(zoom).on('wheel.zoom', null).on('dblclick.zoom', null);
      underlay = svg.append('rect').attr('height', height).classed('underlay', true);
      g = svg.append('g').classed('main', true);
      g.append('path').datum({
        type: 'Sphere'
      }).classed('sphere', true);
      countriesG = g.append('g').classed('countries', true);
      countriesG.selectAll('path').data(topojson.feature($scope.mapData, $scope.mapData.objects['ru_world']).features).enter().append('path').classed('country', true).attr('id', function(d) {
        return d.id;
      }).style('stroke-width', function(d) {
        if (d.id === 'RU') {
          return strokeWidth * 2;
        } else {
          return strokeWidth;
        }
      }).on('mouseover', function(d) {
        var eventData;
        reattach(this);
        if (d.id === 'RU') {
          reattach(d3element.select('.country.without-borders#RU').node());
        }
        if (!countryAbundances[d.id]) {
          return;
        }
        d3.select(this).classed('hovered', true);
        eventData = {
          countryName: _.find($scope.data.countries, {
            'code': d.id
          })['name'],
          flag: d.id,
          abundanceValue: countryAbundances[d.id][resistance][substance],
          nOfSamples: countrySamples[d.id].length,
          topFiveList: topFiveGenerator.get(countrySamples[d.id], countryAbundances[d.id], resistance, substance)
        };
        $rootScope.$broadcast('mapChart.countryInOut', eventData);
        $scope.$apply();
      }).on('mouseout', function() {
        d3.select(this).classed('hovered', false);
        $rootScope.$broadcast('mapChart.countryInOut', {});
        $scope.$apply();
      });
      countriesG.append('path').datum(_.find(topojson.feature($scope.mapData, $scope.mapData.objects['ru_world']).features, {
        'id': 'RU'
      })).classed('country without-borders', true).attr('id', 'RU').style('stroke-width', strokeWidth * 2);
      samplesCountries = _.uniq(_.map($scope.data.samples, 'f-countries'));
      resistance = void 0;
      substance = void 0;
      countryAbundances = {};
      countrySamples = {};
      samplesCountries.forEach(function(countryName) {
        var country;
        country = _.find($scope.data.countries, {
          'name': countryName
        });
        countryAbundances[country.code] = {};
        countrySamples[country.code] = [];
        _.keys($scope.data.resistances).forEach(function(key) {
          countryAbundances[country.code][key] = {
            'overall': void 0
          };
          $scope.data.resistances[key].forEach(function(substance) {
            countryAbundances[country.code][key][substance] = void 0;
          });
        });
      });
      recalcCountryAbundances = function(filteredSamples) {
        samplesCountries.forEach(function(countryName) {
          var cSamples, country;
          country = _.find($scope.data.countries, {
            'name': countryName
          });
          cSamples = samplesFilter.getFilteredSamples(filteredSamples, {
            'f-countries': countryName
          });
          countrySamples[country.code] = cSamples;
          _.keys($scope.data.resistances).forEach(function(key) {
            countryAbundances[country.code][key].overall = abundanceCalculator.getAbundanceValue(cSamples, key, 'overall');
            $scope.data.resistances[key].forEach(function(substance) {
              countryAbundances[country.code][key][substance] = abundanceCalculator.getAbundanceValue(cSamples, key, substance);
            });
          });
        });
      };
      paintMap = function() {
        d3element.selectAll('.country').style('fill', function(d) {
          var value;
          value = void 0;
          if (resistance && substance && countryAbundances[d.id]) {
            value = countryAbundances[d.id][resistance][substance];
          }
          return colorScale.getColorByValue(value);
        });
      };
      $scope.$on('substanceFilter.substanceChanged', function(event, eventData) {
        resistance = eventData.resistance ? eventData.resistance : eventData.substance;
        substance = eventData.resistance ? eventData.substance : 'overall';
        paintMap();
      });
      $scope.$on('filters.filtersChanged', function(event, eventData) {
        var filteredSamples;
        filteredSamples = samplesFilter.getFilteredSamples($scope.data.samples, eventData);
        recalcCountryAbundances(filteredSamples);
        paintMap();
        zoomInCountries(filteredSamples);
      });
      $scope.$on('zoomButtons.zoomIn', function(event, eventData) {
        zoomFromOutside('in');
      });
      $scope.$on('zoomButtons.zoomOut', function(event, eventData) {
        zoomFromOutside('out');
      });
      $document.bind('keydown', function(event) {
        if (event.which !== 27) {
          return;
        }
        zoom.translate([width / 2, height / 2]).scale(goodZoom);
        redrawMap(true);
        $scope.$apply();
      });
      $(window).on('resize', function() {
        width = $element.width();
        minZoom = width / 12;
        goodZoom = width / 6;
        maxZoom = width;
        underlay.attr('width', width);
        zoom.translate([width / 2, height / 2]).center([width / 2, height / 2]).scale(goodZoom).scaleExtent([minZoom, maxZoom]);
        svg.attr('width', width).call(zoom.event);
      });
      $timeout(function() {
        return $(window).resize();
      });
    }
  };
});

app.directive('overflow', function() {
  return {
    restrict: 'A',
    link: function($scope, $element, $attrs) {
      var element;
      element = $element[0];
      $scope.$watch(function() {
        if (element.offsetWidth < element.scrollWidth) {
          $element.addClass('overflow');
        } else {
          $element.removeClass('overflow');
        }
      });
    }
  };
});

app.directive('substanceFilter', function($document, $rootScope) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/substance-filter.html',
    scope: {
      data: '='
    },
    link: function($scope, $element, $attrs) {
      var clickHandler, defaultSubstanceFilterValue, getItem, isSubstanceChangedFromOutside, prepareSubstanceData;
      $scope.isListShown = false;
      $scope.dataset = [];
      _.keys($scope.data.resistances).forEach(function(key) {
        $scope.dataset.push({
          title: key,
          value: key
        });
        if ($scope.data.resistances[key].length < 2) {
          return;
        }
        $scope.data.resistances[key].forEach(function(s) {
          $scope.dataset.push({
            title: s,
            value: s,
            parent: key
          });
        });
      });
      $scope.substanceFilterValue = $scope.dataset[0];
      defaultSubstanceFilterValue = $scope.dataset[0];
      isSubstanceChangedFromOutside = false;
      clickHandler = function(event) {
        if ($element.find(event.target).length) {
          return;
        }
        $scope.isListShown = false;
        $scope.$apply();
        $document.unbind('click', clickHandler);
      };
      $scope.toggleList = function() {
        $scope.isListShown = !$scope.isListShown;
        if ($scope.isListShown) {
          $document.bind('click', clickHandler);
        } else {
          $document.unbind('click', clickHandler);
        }
      };
      getItem = function(item) {
        if (typeof item === 'string') {
          item = _.find($scope.dataset, {
            'value': item
          });
        }
        return item;
      };
      $scope.isItemSelected = function(item) {
        return $scope.substanceFilterValue.value === getItem(item).value;
      };
      $scope.selectItem = function(item) {
        isSubstanceChangedFromOutside = false;
        $scope.substanceFilterValue = getItem(item);
        $scope.isListShown = false;
      };
      prepareSubstanceData = function() {
        var database, eventData, infoLink, substance;
        infoLink = void 0;
        database = void 0;
        if ($scope.substanceFilterValue.value.indexOf('ABX') === -1) {
          substance = _.find($scope.data.substances, {
            'name': $scope.substanceFilterValue.value
          });
          infoLink = substance['infoLink'];
          database = substance['resistance'].indexOf('ABX') === -1 ? 'BacMet' : 'CARD';
        }
        eventData = {
          resistance: $scope.substanceFilterValue.parent,
          substance: $scope.substanceFilterValue.value,
          isSubstanceChangedFromOutside: isSubstanceChangedFromOutside,
          infoLink: infoLink,
          database: database
        };
        return eventData;
      };
      $scope.$watch('substanceFilterValue', function() {
        var infoBlockData;
        infoBlockData = prepareSubstanceData();
        $rootScope.$broadcast('substanceFilter.substanceChanged', infoBlockData);
        if (!isSubstanceChangedFromOutside) {
          defaultSubstanceFilterValue = $scope.substanceFilterValue;
          $rootScope.$broadcast('substanceFilter.defaultSubstanceChanged', infoBlockData);
        }
      });
      $scope.$on('heatmapChart.tempSubstanceChanged', function(event, eventData) {
        isSubstanceChangedFromOutside = true;
        if (eventData) {
          $scope.substanceFilterValue = _.find($scope.dataset, {
            'value': eventData
          });
        } else {
          $scope.substanceFilterValue = defaultSubstanceFilterValue;
        }
      });
      $scope.$on('heatmapChart.defaultSubstanceChanged', function(event) {
        defaultSubstanceFilterValue = $scope.substanceFilterValue;
        $rootScope.$broadcast('substanceFilter.substanceChanged', prepareSubstanceData(), true);
      });
    }
  };
});

app.directive('taxonomyHeatmap', function() {
  return {
    restrict: 'E',
    templateUrl: 'directives/taxonomy-heatmap.html',
    link: function($scope, $rootScope) {
      var changeCellInfo, filterSamples, getTableForSubstance, groupBy;
      $scope.colNameSelect = {
        key: 'col-name-sel',
        dataset: [
          {
            title: 'Genus',
            value: 'genus'
          }, {
            title: 'Family',
            value: 'family'
          }, {
            title: 'Order',
            value: 'order'
          }, {
            title: 'Class',
            value: 'class'
          }
        ]
      };
      groupBy = function(data, field1, field2, applyFunc) {
        var nested, result;
        nested = d3.nest().key(function(d) {
          return d[field1];
        }).key(function(d) {
          return d[field2];
        }).rollup(applyFunc).map(data);
        result = [];
        _.forEach(nested, function(row, rowId) {
          return _.forEach(row, function(value, colId) {
            return result.push(_.fromPairs([[field1, rowId], [field2, colId], ['value', value]]));
          });
        });
        return result;
      };
      getTableForSubstance = function(samples, substance) {
        var notNull, res;
        notNull = function(x) {
          return x !== null;
        };
        res = samples.map(function(sample) {
          var data;
          data = sample.genes[substance];
          if (!data) {
            return null;
          }
          data['id'] = sample.names;
          return data;
        });
        return res.filter(notNull);
      };
      filterSamples = function(all_samples, sample_ids, genes) {
        var genes_set, sample_id_set;
        sample_id_set = d3.set(sample_ids);
        genes_set = d3.set(genes);
        return all_samples.filter(function(s) {
          return sample_id_set.has(s.sampleLower) && genes_set.has(s.gene_idLower);
        });
      };
      changeCellInfo = function(eventData) {
        var filteredSamples, genes, sampleNames;
        $scope.countryName = eventData.countryName;
        $scope.flag = eventData.flag;
        $scope.abundanceValue = eventData.abundanceValue;
        $scope.abundanceValueType = eventData.abundanceValueType;
        $scope.nOfSamples = eventData.nOfSamples;
        $scope.topFiveList = eventData.topFiveList;
        $scope.samples = (eventData.samples || []).length;
        if (eventData.samples) {
          sampleNames = eventData.samples.map(function(s) {
            return s.names.toLowerCase();
          });
          genes = eventData.topFiveList.map(function(g) {
            return g.name.toLowerCase();
          });
          filteredSamples = filterSamples($scope.$parent.sampleGeneTaxa, sampleNames, genes);
          $scope.table = groupBy(filteredSamples, $scope.rowName, $scope.colName.value, function(d) {
            return d.length;
          });
        } else {
          $scope.table = [];
        }
      };
      $scope.$on('heatmapChart.cellChanged', function(event, eventData, ignoreFrozen) {
        return changeCellInfo(eventData);
      });
      $scope.colName = $scope.colNameSelect.dataset[0];
      return $scope.rowName = 'gene_id';
    }
  };
});

app.directive('tips', function() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/tips.html',
    link: function($scope, $element, $attrs) {
      $scope.isInfoShown = {
        upload: false,
        about: false
      };
    }
  };
});

app.directive('zoomButtons', function($rootScope) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: 'directives/zoom-buttons.html',
    link: function($scope, $element, $attrs) {
      $scope.canZoomIn = true;
      $scope.canZoomOut = true;
      $scope.zoomIn = function() {
        $rootScope.$broadcast('zoomButtons.zoomIn');
      };
      $scope.zoomOut = function() {
        $rootScope.$broadcast('zoomButtons.zoomOut');
      };
      $scope.$on('mapChart.canZoomIn', function(event, eventData) {
        $scope.canZoomIn = eventData;
      });
      $scope.$on('mapChart.canZoomOut', function(event, eventData) {
        $scope.canZoomOut = eventData;
      });
    }
  };
});

app.filter('prepareAbundanceValue', function() {
  return function(value, power) {
    var multiplier;
    if (!value) {
      return '0';
    }
    if (!power) {
      power = parseInt(value.toExponential().split('-')[1]);
    }
    multiplier = Math.pow(10, power);
    value *= multiplier;
    value = parseFloat(value.toFixed(2));
    return (value === 1 ? '' : value + '×') + '10<sup>−' + power + '</sup>';
  };
});

app.filter('trust', function($sce) {
  return function(html) {
    return $sce.trustAsHtml(html);
  };
});

app.factory('abundanceCalculator', function() {
  var abundanceCalculator, resistances;
  resistances = {};
  return abundanceCalculator = {
    init: function(data) {
      resistances = data;
    },
    getAbundanceValue: function(samples, resistance, substance) {
      if (substance !== 'overall') {
        return d3.median(_.map(samples, function(s) {
          return s[resistance][substance];
        }));
      } else {
        return d3.mean(_.map(resistances[resistance], function(s) {
          return abundanceCalculator.getAbundanceValue(samples, resistance, s);
        }));
      }
    },
    getGeneAbundanceValue: function(samples, substance, gene) {
      return d3.median(_.map(samples, function(s) {
        return s.genes[substance][gene];
      }));
    }
  };
});

app.factory('colorScale', function(colors) {
  var colorScale, maxPower, minPower, num, scale, scaleDomain, scaleRange;
  scaleDomain = [];
  scaleRange = [];
  minPower = -12;
  maxPower = -4;
  scaleDomain = (function() {
    var i, ref, ref1, results;
    results = [];
    for (num = i = ref = minPower, ref1 = maxPower; ref <= ref1 ? i <= ref1 : i >= ref1; num = ref <= ref1 ? ++i : --i) {
      results.push(Math.pow(10, num));
    }
    return results;
  })();
  scaleRange = _.reverse(colors.baseColors);
  scale = d3.scale.log().domain(scaleDomain).range(scaleRange);
  return colorScale = {
    getColorByValue: function(value) {
      if (!value) {
        return colors.neutral;
      } else {
        return scale(value);
      }
    },
    getDomain: function() {
      return scaleDomain;
    },
    getRange: function() {
      return scaleRange;
    }
  };
});

app.constant('colors', {
  baseColors: ['#7f3b08', '#b35806', '#e08214', '#fdb863', '#efe3e7', '#d8daeb', '#b2abd2', '#8073ac', '#542788'],
  neutral: '#fff'
});

app.factory('dataLoader', function() {
  var csv, dataLoader, json, tsv;
  json = d3.json;
  tsv = d3.tsv;
  csv = d3.csv;
  return dataLoader = {
    getData: function() {
      return d3.queue().defer(json, 'data/map/ru_world.json').defer(tsv, 'data/map/countries.tsv').defer(json, 'data/samples-groups/sample_description.json').defer(json, 'data/samples-groups/group_description_with_genes.json').defer(tsv, 'data/samples-groups/ab_table_total.tsv').defer(tsv, 'data/samples-groups/gene_table_total.tsv').defer(csv, 'data/links.csv').defer(tsv, 'data/samples-groups/samples_gene_taxa.tsv');
    }
  };
});

app.factory('samplesFilter', function() {
  var samplesFilter;
  return samplesFilter = {
    getFilteredSamples: function(samples, filterValues) {
      return _.filter(samples, function(s) {
        return _.every(_.forIn(filterValues), function(value, key) {
          var left, right, sampleValue;
          sampleValue = s[key];
          if ((key === 'f-studies' || key === 'f-countries') && _.isArray(value)) {
            if (value.length) {
              return _.some(value, function(v) {
                return sampleValue === v;
              });
            } else {
              return true;
            }
          } else if (key === 'f-ages') {
            left = parseInt(value.split('...')[0]);
            right = value.split('...')[1];
            if (right === '∞') {
              right = 2e308;
            } else {
              right = parseInt(right);
            }
            return (left <= sampleValue && sampleValue <= right);
          } else {
            return sampleValue === value;
          }
        });
      });
    }
  };
});

app.factory('tools', function() {
  var tools;
  return tools = {
    sortAlphabeticaly: function(a, b) {
      if (a.toLowerCase() < b.toLowerCase()) {
        return -1;
      }
      if (a.toLowerCase() > b.toLowerCase()) {
        return 1;
      }
      return 0;
    },
    searchInIndexedIntervals: function(indexedIntervals, value) {
      var begin, end, interval, intervalStr, k, len;
      for (k = 0, len = indexedIntervals.length; k < len; k++) {
        interval = indexedIntervals[k];
        begin = interval[0], end = interval[1], intervalStr = interval[2];
        if ((begin <= value && value <= end)) {
          return intervalStr;
        }
      }
      return void 0;
    },
    getPermutations: function(array) {
      var allCasesOfRest, i, j, result;
      if (!array.length) {
        return [];
      } else if (array.length === 1) {
        return array[0].map(function(a) {
          return [a];
        });
      } else {
        result = [];
        allCasesOfRest = tools.getPermutations(array.slice(1));
        j = 0;
        while (j < array[0].length) {
          i = 0;
          while (i < allCasesOfRest.length) {
            result.push([array[0][j]].concat(allCasesOfRest[i]));
            i++;
          }
          j++;
        }
        return result;
      }
    }
  };
});

app.factory('topFiveGenerator', function(abundanceCalculator, tools) {
  var getGenesAbundancesList, substances, topFiveGenerator;
  substances = [];
  getGenesAbundancesList = function(samples, sName) {
    var substance;
    substance = _.find(substances, {
      'name': sName
    });
    return substance.genes.map(function(gene) {
      return {
        name: gene,
        value: abundanceCalculator.getGeneAbundanceValue(samples, sName, gene)
      };
    });
  };
  return topFiveGenerator = {
    init: function(data) {
      substances = data;
    },
    get: function(samples, abundances, resistance, substance) {
      var list;
      if (substance === 'overall') {
        if (resistance === 'ABX determinants') {
          list = _.keys(abundances['ABX determinants']).filter(function(key) {
            return key !== 'overall';
          }).map(function(key) {
            return {
              name: key,
              value: abundances['ABX determinants'][key]
            };
          });
        } else if (resistance === 'ABX mutations') {
          list = [];
        } else {
          list = getGenesAbundancesList(samples, resistance);
        }
      } else {
        list = getGenesAbundancesList(samples, substance);
      }
      _.remove(list, function(l) {
        return !l.value;
      });
      list.sort(function(a, b) {
        var d;
        d = b.value - a.value;
        if (d) {
          return d;
        }
        return tools.sortAlphabeticaly(a.name, b.name);
      });
      return _.take(list, 5);
    }
  };
});
