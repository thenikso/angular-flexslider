'use strict'

angular.module('angular-flexslider', [])
	.directive 'flexSlider', ['$parse', '$timeout', ($parse, $timeout) ->
		restrict: 'AE'
		scope: no
		replace: yes
		transclude: yes
		template: '<div class="flexslider-container"></div>'
		compile: (element, attr, linker) ->
			($scope, $element) ->
				match = (attr.slide || attr.flexSlide).match /^\s*(.+)\s+in\s+(.*?)(?:\s+track\s+by\s+(.+?))?\s*$/
				indexString = match[1]
				collectionString = match[2]
				trackBy = if angular.isDefined(match[3]) then $parse(match[3]) else $parse("#{indexString}")

				flexsliderDiv = null
				slidesItems = {}

				getTrackFromItem = (collectionItem, index) ->
					locals = {}
					locals[indexString] = collectionItem
					locals['$index'] = index
					trackBy($scope, locals)

				addSlide = (collectionItem, index, callback) ->
					# Generating tracking element
					track = getTrackFromItem collectionItem, index
					# See if it's unique
					if slidesItems[track]?
						throw "Duplicates in a repeater are not allowed. Use 'track by' expression to specify unique keys."
					# Create new item
					childScope = $scope.$new()
					childScope[indexString] = collectionItem
					childScope['$index'] = index
					linker childScope, (clone) ->
						slideItem =
							collectionItem: collectionItem
							childScope: childScope
							element: clone
						slidesItems[track] = slideItem
						callback?(slideItem)

				removeSlide = (collectionItem, index) ->
					track = getTrackFromItem collectionItem, index
					slideItem = slidesItems[track]
					return unless slideItem?
					delete slidesItems[track]
					slideItem.childScope.$destroy()
					slideItem

				$scope.$watchCollection collectionString, (collection, oldCollection) ->
					# Early exit if no collection
					return unless (collection?.length or oldCollection?.length)
					# If flexslider is already initialized, add or remove slides
					if flexsliderDiv?
						slider = flexsliderDiv.data 'flexslider'
						currentSlidesLength = Object.keys(slidesItems).length
						# Get an associative array of track to collection item
						collection ?= []
						trackCollection = {}
						for c, i in collection
							trackCollection[getTrackFromItem(c, i)] = c
						# Generates arrays of collection items to add and remvoe
						toAdd = ({ value: c, index: i } for c, i in collection when not slidesItems[getTrackFromItem(c, i)]?)
						toRemove = (i.collectionItem for t, i of slidesItems when not trackCollection[t]?)
						# Workaround to a still unresolved problem in using flexslider.addSlide
						if (toAdd.length == 1 and toRemove.length == 0) or toAdd.length == 0
							# Remove items
							for e in toRemove
								e = removeSlide e, collection.indexOf(e)
								slider.removeSlide e.element
							# Add items
							for e in toAdd
								idx = e.index
								addSlide e.value, idx, (item) ->
									idx = undefined if idx == currentSlidesLength
									$scope.$evalAsync ->
										slider.addSlide(item.element, idx)
							# Early exit
							return

					# Create flexslider container
					slidesItems = {}
					flexsliderDiv?.remove()
					slides = angular.element('<ul class="slides"></ul>')
					flexsliderDiv = angular.element('<div class="flexslider"></div>')
					flexsliderDiv.append slides
					$element.append flexsliderDiv

					# Generate slides
					addSlide(c, i, (item) -> slides.append item.element) for c, i in collection

					# Options are derived from flex-slider arguments
					options = {}
					for attrKey, attrVal of attr
						if attrKey.indexOf('$') == 0
							continue
						unless isNaN(n = parseInt(attrVal))
							options[attrKey] = n
							continue
						if attrVal in ['false', 'true']
							options[attrKey] = attrVal is 'true'
							continue
						if attrKey in ['start', 'before', 'after', 'end', 'added', 'removed']
							options[attrKey] = do (attrVal) ->
								f = $parse(attrVal)
								(slider) -> $scope.$apply -> f($scope, { '$slider': { element: slider } })
							continue
						if attrKey in ['startAt']
							options[attrKey] = $parse(attrVal)($scope)
							continue
						options[attrKey] = attrVal

					# Apply sliderId if present
					if not options.sliderId and attr.id
						options.sliderId = "#{attr.id}-slider"
					if options.sliderId
					  flexsliderDiv.attr('id', options.sliderId)

					# Running flexslider
					$timeout (-> flexsliderDiv.flexslider options), 0
				]
