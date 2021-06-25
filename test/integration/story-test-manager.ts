import { HardhatRuntimeEnvironment } from 'hardhat/types'
import Mocha from 'mocha'

import { generateStoryDomains } from '../helpers/story/generator/story-generator'
import {
  generateTests,
  TestScenario,
  TestScenarioDomain,
} from '../helpers/story/story-helpers'

export const generateAllStoryTests = (
  hre: HardhatRuntimeEnvironment
): Mocha => {
  const allTestStoryDomains: TestScenarioDomain[] =
    generateStoryDomains(hre)

  // var allGeneratedSuites: Array<Mocha.Suite> = []

  // var allMochaInstances: Array<Mocha> = []

  const mochaInstance = new Mocha()
  mochaInstance.timeout(19000)

  for (const storyDomain of allTestStoryDomains) {
    const suiteInstance = Mocha.Suite.create(
      mochaInstance.suite,
      'Story Test Suite - '.concat(storyDomain.domainName)
    )

    console.log('storyDomain ', storyDomain)

    for (const scenario of storyDomain.scenarios) {
      const testsForDomain = generateTests(hre, scenario, suiteInstance)
    }
  }

  return mochaInstance
}
