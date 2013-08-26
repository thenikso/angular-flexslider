'use strict'

angular.module('angular-flexslider', [])
	.directive 'flexSlider', ($parse, $timeout) ->
		restrict: 'AE'
		scope: no
		replace: yes
		transclude: yes
		template: '<div class="flexslider-container"></div>'
		compile: (element, attr, linker) ->
			match = attr.slide.match /^\s*(.+)\s+in\s+(.*?)(?:\s+track\s+by\s+(.+?))?\s*$/
			indexString = match[1]
			collectionString = match[2]
			trackBy = if angular.isDefined(match[3]) then $parse(match[3]) else $parse("#{indexString}")

			flexsliderDiv = null
			slidesItems = []

			oldCollection = null

			($scope, $element) ->
				getTrackFromItem = (collectionItem) ->
					locals = {}
					locals[indexString] = collectionItem
					trackBy($scope, locals)

				addSlide = (collectionItem, callback) ->
					# Generating tracking element
					track = getTrackFromItem collectionItem
					# See if it's unique
					for item in slidesItems when item.track is track
						throw "Duplicates in a repeater are not allowed. Use 'track by' expression to specify unique keys."
						break
					# Create new item
					childScope = $scope.$new()
					childScope[indexString] = collectionItem
					linker childScope, (clone) ->
						slideItem =
							track: track
							collectionItem: collectionItem
							childScope: childScope
							element: clone
						slidesItems.push slideItem
						callback?(slideItem)

				removeSlide = (collectionItem) ->
					track = getTrackFromItem collectionItem
					slideItem = item for item in slidesItems when item.track is track
					return unless slideItem?
					i = slidesItems.indexOf(slideItem)
					return if i < 0
					slidesItems = slidesItems.slice(i, 1)
					slideItem.childScope.$destroy()
					slideItem

				$scope.$watchCollection collectionString, (collection) ->

					# If flexslider is already initialized, add or remove slides
					if flexsliderDiv?
						slider = flexsliderDiv.data 'flexslider'
						collection ?= []
						toAdd = collection.filter (e) -> oldCollection.indexOf(e) < 0
						toRemove = (oldCollection ? []).filter (e) -> collection.indexOf(e) < 0

						for e in toRemove
							e = removeSlide e
							slider.removeSlide e.element

						for e in toAdd
							addSlide e, (item) ->
								idx = collection.indexOf(e)
								idx = undefined if idx == oldCollection?.length
								$scope.$evalAsync ->
									slider.addSlide(item.element, idx)

						oldCollection = collection.slice(0)
						return

					# Early exit if no collection
					return unless collection?
					oldCollection = collection.slice(0)

					# Create flexslider container
					slides = angular.element('<ul class="slides"></ul>')
					flexsliderDiv = angular.element('<div class="flexslider"></div>')
					flexsliderDiv.append slides
					$element.append flexsliderDiv

					# Generate slides
					addSlide(c, (item) -> slides.append item.element) for c in collection

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
								-> $scope.$apply -> f($scope, {})
							continue
						options[attrKey] = attrVal

					# Running flexslider
					$timeout (-> flexsliderDiv.flexslider options), 0
