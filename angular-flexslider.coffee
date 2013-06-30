'use strict'

angular.module('angular-flexslider', [])
	.directive 'flexSlider', ->
		restrict: 'AE'
		scope: no
		replace: yes
		transclude: yes
		template: '<div class="flexslider-container"></div>'
		compile: (element, attr, linker) -> ($scope, $element, $attr) ->
			match = $attr.slide.match /^\s*(.+)\s+in\s+(.*?)\s*$/
			indexString = match[1]
			collectionString = match[2]
			elementsScopes = []
			flexsliderDiv = null

			$scope.$watch collectionString, (collection) ->
				# Remove old flexslider
				if elementsScopes.length > 0 or flexsliderDiv?
					$element.children().remove()
					for e in elementsScopes
						e.$destroy()
					elementsScopes = []

				# Create flexslider container
				slides = $('<ul class="slides"></ul>')
				flexsliderDiv = $('<div class="flexslider"></div>')
				flexsliderDiv.append slides
				$element.append flexsliderDiv

				# Early exit if no collection
				return unless collection?

				# Generate slides
				for c in collection
					childScope = $scope.$new()
					childScope[indexString] = c
					linker childScope, (clone) ->
						slides.append clone
						elementsScopes.push childScope

				# Running flexslider
				# Options are derived from flex-slider arguments
				for attrKey, attrVal of $attr
					if attrKey.indexOf('$') == 0
						continue
					unless isNaN(n = parseInt(attrVal))
						$attr[attrKey] = n
						continue
					if attrVal in ['false', 'true']
						$attr[attrKey] = attrVal is 'true'
						continue
					if attrKey in ['start', 'before', 'after', 'end', 'added', 'removed']
						$attr[attrKey] = ((evalExp) -> ->
							$scope.$apply -> $scope.$eval evalExp)(attrVal)
						continue
				setTimeout (-> $scope.$apply -> flexsliderDiv.flexslider $attr), 0
