{**
 * templates/authorDashboard/authorDashboard.tpl
 *
 * Copyright (c) 2014-2020 Simon Fraser University
 * Copyright (c) 2003-2020 John Willinsky
 * Distributed under the GNU GPL v3. For full terms see the file docs/COPYING.
 *
 * Display the author dashboard.
 *}
{strip}
	{assign var=primaryAuthor value=$submission->getPrimaryAuthor()}
	{if !$primaryAuthor}
		{assign var=authors value=$submission->getAuthors()}
		{assign var=primaryAuthor value=$authors[0]}
	{/if}
	{assign var=submissionTitleSafe value=$submission->getLocalizedTitle()|strip_unsafe_html}
	{if $primaryAuthor}
		{assign var="pageTitleTranslated" value=$primaryAuthor->getFullName()|concat:", ":$submissionTitleSafe}
	{else}
		{assign var="pageTitleTranslated" value=$submissionTitleSafe}
	{/if}
	{include file="common/header.tpl" suppressPageTitle=true}
{/strip}

<div class="pkp_page_content">
	{assign var="uuid" value=""|uniqid|escape}
	<div id="workflow-{$uuid}" class="pkpWorkflow">
		<pkp-header :is-one-line="true" class="pkpWorkflow__header">
			<h1 class="pkpWorkflow__identification">
				<span class="pkpWorkflow__identificationId">{{ submission.id }}</span>
				<span class="pkpWorkflow__identificationDivider">/</span>
				<span class="pkpWorkflow__identificationAuthor">
					{{ currentPublication.authorsStringShort }}
				</span>
				<span class="pkpWorkflow__identificationDivider">/</span>
				<span class="pkpWorkflow__identificationTitle">
					{{ localizeSubmission(currentPublication.title, currentPublication.locale) }}
				</span>
			</h1>
			<template slot="actions">
				<pkp-button
					v-if="uploadFileUrl"
					:label="i18n.uploadFile"
					ref="uploadFileButton"
					@click="openFileUpload"
				></pkp-button>
				<pkp-button
					label="{translate key="editor.submissionLibrary"}"
					@click="openLibrary"
				></pkp-button>
			</template>
		</pkp-header>
		<tabs>
			<tab id="publication" label="{translate key="submission.publication"}">
				{include file="controllers/notification/inPlaceNotification.tpl" notificationId="authorDashboardNotification" requestOptions=$authorDashboardNotificationRequestOptions}
				<div class="pkpPublication" ref="publication" aria-live="polite">
					<pkp-header class="pkpPublication__header">
						<span class="pkpPublication__status">
							<strong>{{ i18n.status }}</strong>
							<span v-if="workingPublication.status === getConstant('STATUS_QUEUED') && workingPublication.id === currentPublication.id" class="pkpPublication__statusUnpublished">{translate key="publication.status.unscheduled"}</span>
							<span v-else-if="workingPublication.status === getConstant('STATUS_SCHEDULED')">{translate key="publication.status.scheduled"}</span>
							<span v-else-if="workingPublication.status === getConstant('STATUS_PUBLISHED')" class="pkpPublication__statusPublished">{translate key="publication.status.published"}</span>
							<span v-else class="pkpPublication__statusUnpublished">{translate key="publication.status.unpublished"}</span>
						</span>
							<span v-if="publicationList.length > 1" class="pkpPublication__version">
								<strong tabindex="0">{{ i18n.version }}</strong> {{ workingPublication.id }}
								<dropdown
									class="pkpPublication__versions"
									label="{translate key="publication.version.all"}"
									:is-link="true"
									submenu-label="{translate key="common.submenu"}"
								>
									<ul>
										<li v-for="publication in publicationList" :key="publication.id">
											<button
												class="pkpDropdown__action"
												:disabled="publication.id === workingPublication.id"
												@click="setWorkingPublicationById(publication.id)"
											>
												{{ publication.id }} /
												<template v-if="publication.status === getConstant('STATUS_QUEUED') && publication.id === currentPublication.id">{translate key="publication.status.unscheduled"}</template>
												<template v-else-if="publication.status === getConstant('STATUS_SCHEDULED')">{translate key="publication.status.scheduled"}</template>
												<template v-else-if="publication.status === getConstant('STATUS_PUBLISHED')">{translate key="publication.status.published"}</template>
												<template v-else>{translate key="publication.status.unpublished"}</template>
											</button>
										</li>
									</ul>
								</dropdown>
							</span>
							{if $canPublish}
							<span class="pkpPublication__relation">
								<dropdown
									class="pkpWorkflow__relation"
									label="{translate key="publication.relation"}"
								>
									<pkp-form class="pkpWorkflow__relateForm" v-bind="components.{$smarty.const.FORM_ID_RELATION}" @set="set">
								</dropdown>
							</span>
							{/if}
							{if $canPublish}
								<template slot="actions">
									<pkp-button
										v-if="workingPublication.status === getConstant('STATUS_QUEUED')"
										ref="publish"
										:label="submission.status === getConstant('STATUS_PUBLISHED') ? i18n.publish : i18n.schedulePublication"
										@click="openPublish"
									></pkp-button>
									<pkp-button
										v-else-if="workingPublication.status === getConstant('STATUS_SCHEDULED')"
										label="{translate key="publication.unschedule"}"
										:is-warnable="true"
										@click="openUnpublish"
									></pkp-button>
									<pkp-button
										v-else-if="workingPublication.status === getConstant('STATUS_PUBLISHED')"
										label="{translate key="publication.unpublish"}"
										:is-warnable="true"
										@click="openUnpublish"
									></pkp-button>
									<pkp-button
										v-if="canCreateNewVersion"
										ref="createVersion"
										label="{translate key="publication.createVersion"}"
										@click="createVersion"
									></pkp-button>
								</template>
							{/if}
					</pkp-header>
					<div
						v-if="workingPublication.status === getConstant('STATUS_PUBLISHED')"
						class="pkpPublication__versionPublished"
					>
						{translate key="publication.editDisabled"}
					</div>
					<tabs :is-side-tabs="true" class="pkpPublication__tabs" :label="publicationTabsLabel">
						<tab id="titleAbstract" label="{translate key="publication.titleAbstract"}">
							<pkp-form v-bind="components.{$smarty.const.FORM_TITLE_ABSTRACT}" @set="set" />
						</tab>
						<tab id="contributors" label="{translate key="publication.contributors"}">
							<div id="contributors-grid" ref="contributors">
								<spinner></spinner>
							</div>
						</tab>
						{if $metadataEnabled}
							<tab id="metadata" label="{translate key="submission.informationCenter.metadata"}">
								<pkp-form v-bind="components.{$smarty.const.FORM_METADATA}" @set="set" />
							</tab>
						{/if}
						<tab v-if="supportsReferences" id="citations" label="{translate key="submission.citations"}">
							<pkp-form v-bind="components.{$smarty.const.FORM_CITATIONS}" @set="set" />
						</tab>
						<tab id="galleys" label="{translate key="submission.layout.galleys"}">
							<div id="representations-grid" ref="representations">
								<spinner></spinner>
							</div>
						</tab>
						<tab id="queries" label="{translate key="submission.queries.production"}">
							<div id="queries-grid" ref="queries">
							{include file="controllers/tab/authorDashboard/production.tpl"}
							</div>
						</tab>
						{call_hook name="Template::Workflow::Publication"}
					</tabs>
					<span class="pkpPublication__mask" :class="publicationMaskClasses">
						<spinner></spinner>
					</span>
				</div>
			</tab>
			{call_hook name="Template::Workflow"}
		</tabs>
	</div>
	<script type="text/javascript">
		pkp.registry.init('workflow-{$uuid}', 'WorkflowContainer', {$workflowData|json_encode});
	</script>
</div>

{include file="common/footer.tpl"}
